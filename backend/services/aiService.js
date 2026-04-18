const { GoogleGenAI } = require('@google/genai');

const OPENAI_API_URL = 'https://api.openai.com/v1/chat/completions';
const OPENAI_DEFAULT_MODEL = 'gpt-4o-mini';
const GEMINI_DEFAULT_MODEL = 'gemini-2.5-flash';
const GEMINI_FALLBACK_MODELS = [
  'gemini-2.5-flash',
  'gemini-2.5-flash-lite',
  'gemini-2.0-flash',
  'gemini-1.5-flash-latest',
];

const createPrompt = (question) =>
  [
    'You are a coaching tutor.',
    'Answer the student doubt with:',
    '1) A clear explanation in simple language.',
    '2) A short step-by-step approach.',
    '3) One small example.',
    '4) Common mistake to avoid.',
    '',
    `Student doubt: ${question}`,
  ].join('\n');

const parseOpenAiExplanation = (json) => {
  if (!json || typeof json !== 'object') {
    return '';
  }

  const choices = Array.isArray(json.choices) ? json.choices : [];
  for (const choice of choices) {
    const content =
      choice &&
      choice.message &&
      typeof choice.message.content === 'string' &&
      choice.message.content.trim();
    if (content) {
      return content;
    }
  }

  return '';
};

const asDataUrl = (mimeType, base64Data) =>
  `data:${mimeType};base64,${base64Data}`;

const unique = (values) => [...new Set(values.filter(Boolean))];

const stripModelPrefix = (modelName) =>
  typeof modelName === 'string' ? modelName.replace(/^models\//, '') : '';

const isGeminiGenerateContentModel = (model) =>
  model &&
  Array.isArray(model.supportedActions) &&
  model.supportedActions.includes('generateContent');

const isMissingGeminiModelError = (error) =>
  /not found|not supported|generatecontent|models\/.+is not found/i.test(
    error && error.message ? error.message : ''
  );

const createGeminiClient = () => {
  const apiKey = (process.env.GEMINI_API_KEY || '').trim();
  if (!apiKey) {
    return null;
  }
  return new GoogleGenAI({ apiKey });
};

const buildGeminiContents = ({ question, imageBase64, imageMimeType }) => {
  const questionText =
    typeof question === 'string' && question.trim().length > 0
      ? question.trim()
      : 'Please explain the question shown in the image.';

  const parts = [{ text: createPrompt(questionText) }];
  if (imageBase64 && imageMimeType) {
    parts.push({
      inlineData: {
        mimeType: imageMimeType,
        data: imageBase64,
      },
    });
  }

  return [{ role: 'user', parts }];
};

const extractGeminiExplanation = (response) => {
  if (!response || typeof response !== 'object') {
    return '';
  }

  if (typeof response.text === 'string' && response.text.trim()) {
    return response.text.trim();
  }

  const candidates = Array.isArray(response.candidates) ? response.candidates : [];
  for (const candidate of candidates) {
    const parts =
      candidate &&
      candidate.content &&
      Array.isArray(candidate.content.parts)
        ? candidate.content.parts
        : [];
    const text = parts
      .map((part) => (part && typeof part.text === 'string' ? part.text : ''))
      .join('\n')
      .trim();
    if (text) {
      return text;
    }
  }

  return '';
};

const listGeminiGenerateContentModels = async (ai) => {
  const pager = await ai.models.list({ config: { pageSize: 100 } });
  const models = [];

  for await (const model of pager) {
    if (!isGeminiGenerateContentModel(model)) {
      continue;
    }

    const cleaned = stripModelPrefix(model.name);
    if (cleaned) {
      models.push(cleaned);
    }
  }

  return unique(models);
};

const selectFallbackGeminiModel = (
  availableModels,
  preferredModels,
  excludedModels = []
) => {
  const preferred = unique(preferredModels.map(stripModelPrefix));
  const excluded = new Set(excludedModels.map(stripModelPrefix));
  const available = new Set(availableModels.map(stripModelPrefix));

  for (const model of preferred) {
    if (available.has(model) && !excluded.has(model)) {
      return model;
    }
  }

  const firstFlashModel = availableModels.find((model) =>
    /^gemini-.*flash/i.test(model) && !excluded.has(stripModelPrefix(model))
  );
  if (firstFlashModel) {
    return firstFlashModel;
  }

  return (
    availableModels.find((model) => !excluded.has(stripModelPrefix(model))) ||
    null
  );
};

const generateWithGeminiModel = async ({
  ai,
  model,
  question,
  imageBase64,
  imageMimeType,
}) => {
  const response = await ai.models.generateContent({
    model,
    contents: buildGeminiContents({ question, imageBase64, imageMimeType }),
    config: {
      temperature: 0.3,
    },
  });

  const explanation = extractGeminiExplanation(response);
  if (!explanation) {
    const error = new Error('Gemini returned an empty response');
    error.status = 502;
    throw error;
  }

  return explanation;
};

const callOpenAi = async ({ question, imageBase64, imageMimeType }) => {
  const apiKey = (process.env.OPENAI_API_KEY || '').trim();
  if (!apiKey) {
    return null;
  }

  const model = (process.env.OPENAI_MODEL || OPENAI_DEFAULT_MODEL).trim();
  const questionText =
    typeof question === 'string' && question.trim().length > 0
      ? question.trim()
      : 'Please explain the question shown in the image.';

  const userContent = [{ type: 'text', text: createPrompt(questionText) }];
  if (imageBase64 && imageMimeType) {
    userContent.push({
      type: 'image_url',
      image_url: {
        url: asDataUrl(imageMimeType, imageBase64),
      },
    });
  }

  const response = await fetch(OPENAI_API_URL, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${apiKey}`,
    },
    body: JSON.stringify({
      model,
      messages: [{ role: 'user', content: userContent }],
      temperature: 0.3,
    }),
  });

  const text = await response.text();
  let json = null;
  try {
    json = text ? JSON.parse(text) : null;
  } catch (_) {
    json = null;
  }

  if (!response.ok) {
    const message =
      (json &&
        json.error &&
        typeof json.error.message === 'string' &&
        json.error.message) ||
      'OpenAI request failed';
    const error = new Error(message);
    error.status = 502;
    throw error;
  }

  const explanation = parseOpenAiExplanation(json);
  if (!explanation) {
    const error = new Error('OpenAI returned an empty response');
    error.status = 502;
    throw error;
  }

  return explanation;
};

const callGemini = async ({ question, imageBase64, imageMimeType }) => {
  const ai = createGeminiClient();
  if (!ai) {
    return null;
  }

  const configuredModel = stripModelPrefix(
    (process.env.GEMINI_MODEL || GEMINI_DEFAULT_MODEL).trim()
  );

  try {
    return await generateWithGeminiModel({
      ai,
      model: configuredModel,
      question,
      imageBase64,
      imageMimeType,
    });
  } catch (error) {
    if (!isMissingGeminiModelError(error)) {
      error.status = error.status || 502;
      throw error;
    }

    const availableModels = await listGeminiGenerateContentModels(ai);
    const fallbackModel = selectFallbackGeminiModel(availableModels, [
      ...GEMINI_FALLBACK_MODELS,
    ], [configuredModel]);

    if (!fallbackModel) {
      const modelError = new Error(
        `Configured Gemini model "${configuredModel}" failed and no alternate generateContent model was available`
      );
      modelError.status = 502;
      throw modelError;
    }

    console.warn(
      `Gemini model "${configuredModel}" failed with "${error.message}". Retrying with "${fallbackModel}".`
    );

    return generateWithGeminiModel({
      ai,
      model: fallbackModel,
      question,
      imageBase64,
      imageMimeType,
    });
  }
};

const solveDoubt = async ({ question, imageBase64, imageMimeType }) => {
  if (typeof fetch !== 'function') {
    const error = new Error('Global fetch is unavailable on this Node version');
    error.status = 500;
    throw error;
  }

  const openAiKey = (process.env.OPENAI_API_KEY || '').trim();
  const geminiKey = (process.env.GEMINI_API_KEY || '').trim();
  if (!openAiKey && !geminiKey) {
    const error = new Error(
      'AI service is not configured. Set OPENAI_API_KEY (recommended) or GEMINI_API_KEY on server'
    );
    error.status = 503;
    throw error;
  }

  if (openAiKey) {
    return callOpenAi({ question, imageBase64, imageMimeType });
  }

  return callGemini({ question, imageBase64, imageMimeType });
};

module.exports = {
  solveDoubt,
};
