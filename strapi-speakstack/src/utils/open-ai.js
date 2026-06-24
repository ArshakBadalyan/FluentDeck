const OpenAI = require("openai");
const systemMessages = require("./open-ai-system-messages.json");
const { sanitizeDbText } = require("./sanitize-db-text");

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
});
const openaiDavo = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY_DAVO,
});

function extractBodyHtml(initialText) {
  if (typeof initialText !== "string") {
    return "";
  }
  const lower = initialText.toLowerCase();
  const open = lower.indexOf("<body>");
  const close = lower.lastIndexOf("</body>");
  if (open !== -1 && close !== -1 && close > open) {
    return initialText.substring(open + 6, close);
  }
  return initialText.trim();
}

function stripHtml(text) {
  return String(text)
    .replace(/<[^>]*>/g, " ")
    .replace(/\s+/g, " ")
    .trim();
}

function truncateText(text, maxLength) {
  const value = sanitizeDbText(text);
  if (value.length <= maxLength) {
    return value;
  }
  return value.slice(0, maxLength - 1).trimEnd() + "…";
}

const getSolution = async (exercise, answer, category, categoryID) => {
  let systemMessage = "";
  if (systemMessages[categoryID]) {
    systemMessage = systemMessages[categoryID];
  } else {
    systemMessage = systemMessages["default"];
  }
  try {
    return await openai.chat.completions.create({
      model: "gpt-5.2",
      messages: [
        {
          "role": "system",
          "content": systemMessage
        },
        {
          "role": "user",
          "content": category + '.\n' + exercise+ '.\n' + answer
        }
      ],
      temperature: 1.34,
      max_completion_tokens: 4095,
      top_p: 0.7,
      frequency_penalty: 0,
      presence_penalty: 0,
    });
  } catch (error) {
    return error
  }
};

const getSolutionSeo = async (
  exercise,
  answer,
  categoryName,
  solutionHtml = ""
) => {
  const systemMessage =
    systemMessages.solutionSeo ||
    'Return JSON only: {"seo_title":"...","seo_description":"..."}';

  const userLines = [
    `Thema: ${categoryName}`,
    `Aufgabe: ${exercise}`,
    `Antwort: ${answer}`,
  ];
  const solutionExcerpt = truncateText(stripHtml(solutionHtml), 400);
  if (solutionExcerpt) {
    userLines.push(`Lösung (Auszug): ${solutionExcerpt}`);
  }

  try {
    return await openai.chat.completions.create({
      model: "gpt-5.2",
      messages: [
        {
          role: "system",
          content: systemMessage,
        },
        {
          role: "user",
          content: userLines.join("\n"),
        },
      ],
      temperature: 0.75,
      max_completion_tokens: 300,
      top_p: 0.9,
      frequency_penalty: 0.2,
      presence_penalty: 0.2,
      response_format: { type: "json_object" },
    });
  } catch (error) {
    return error;
  }
};

function parseSolutionSeoResponse(openAIResponse) {
  if (!openAIResponse || openAIResponse.error) {
    return null;
  }

  const content = openAIResponse?.choices?.[0]?.message?.content;
  if (typeof content !== "string" || content.trim() === "") {
    return null;
  }

  try {
    const parsed = JSON.parse(content);
    const seoTitle = truncateText(parsed.seo_title || "", 60);
    const seoDescription = truncateText(parsed.seo_description || "", 150);
    if (!seoTitle || !seoDescription) {
      return null;
    }
    return {
      seo_title: seoTitle,
      seo_description: seoDescription,
    };
  } catch (error) {
    return null;
  }
}

const getCategoryLesson = async (
  categoryName,
  categoryID,
  exercisesText,
  schoolClassLabel = ""
) => {
  const lessons = systemMessages.categoryLesson;
  if (!lessons) {
    return new Error("categoryLesson prompts missing in open-ai-system-messages.json");
  }
  const sid = String(categoryID);
  const systemMessage = lessons[sid] || lessons.default;

  const userLines = [];
  if (typeof schoolClassLabel === "string" && schoolClassLabel.trim() !== "") {
    userLines.push(`Schulklasse: ${schoolClassLabel.trim()}`);
    userLines.push("");
  }
  userLines.push("Thema (Kategoriename):");
  userLines.push(categoryName);
  userLines.push("");
  userLines.push("Beispielaufgaben aus dieser Kategorie (zur Einordnung von Schwierigkeit und Notation):");
  userLines.push(exercisesText);
  const userContent = userLines.join("\n");
  try {
    return await openai.chat.completions.create({
      model: "gpt-5.2",
      messages: [
        {
          role: "system",
          content: systemMessage,
        },
        {
          role: "user",
          content: userContent,
        },
      ],
      temperature: 0.75,
      max_completion_tokens: 16384,
      top_p: 0.9,
      frequency_penalty: 0,
      presence_penalty: 0,
    });
  } catch (error) {
    return error;
  }
};

/** @param {unknown} v */
function normalizeWrongAnswersList(v) {
  if (v == null) {
    return [];
  }
  if (Array.isArray(v)) {
    return v.map((x) => String(x));
  }
  if (typeof v === "string" && v.trim() === "") {
    return [];
  }
  return [String(v)];
}

const multistepExerciseFunctionParameters = {
  type: "object",
  properties: {
    exercises: {
      type: "array",
      items: {
        type: "object",
        description:
          "One multistep MC exercise. Main step: exercise, correctAnswer, wrongAnswers. Follow-ups: answer_1+wrong_answers_1 through answer_4+wrong_answers_4 (never use correctAnswer1). Then secondAnswer if needed.",
        properties: {
          exercise: {
            type: "string",
            description: "Main question stem (richtext/HTML/MathJax allowed)",
          },
          correctAnswer: {
            type: "string",
            description:
              "Correct option for the MAIN step only (step 0). For follow-up steps use answer_1..answer_4, not correctAnswer2 etc.",
          },
          wrongAnswers: {
            type: "array",
            items: { type: "string" },
            description:
              "Wrong options for the main step (distractors). The number of items must match the sample exercise for the main step (length = number of wrong options, not necessarily 3).",
          },
          secondAnswer: {
            type: "string",
            description:
              "Optional: the final result after the LAST follow-up step only (e.g. simplified number or solution). Empty if the topic examples leave second_answer empty. Not an intermediate step.",
          },
          answer_1: {
            type: "string",
            description:
              "Correct option for follow-up 1; step 1 is posed right after the main step. The line the student reads for this step is the main step's correct answer (empty if no follow-ups)",
          },
          wrong_answers_1: {
            type: "array",
            items: { type: "string" },
            description:
              "Wrong distractors for follow-up 1; count must match the sample for step 1, or empty array if unused",
          },
          answer_2: {
            type: "string",
            description:
              "Correct for follow-up 2; stem context is follow-up 1's correct answer (empty if chain ends)",
          },
          wrong_answers_2: {
            type: "array",
            items: { type: "string" },
            description:
              "Wrong distractors for follow-up 2; count must match sample or [] if unused",
          },
          answer_3: {
            type: "string",
            description:
              "Correct for follow-up 3; stem context is follow-up 2's correct answer",
          },
          wrong_answers_3: {
            type: "array",
            items: { type: "string" },
            description:
              "Wrong distractors for follow-up 3; count must match sample or [] if unused",
          },
          answer_4: {
            type: "string",
            description:
              "Correct for follow-up 4; stem context is follow-up 3's correct answer",
          },
          wrong_answers_4: {
            type: "array",
            items: { type: "string" },
            description:
              "Wrong distractors for follow-up 4; count must match sample or [] if unused",
          },
        },
        required: ["exercise", "correctAnswer", "wrongAnswers"],
      },
    },
  },
  required: ["exercises"],
};

const createNewQuestions = async (content, categoryID, questionsCount) => {
  const basePrompt = systemMessages.newQuestions.mainText;
  const systemMessage = basePrompt.replace(
    "{{COUNT}}",
    questionsCount
  );
  let additionalMessage = systemMessages.newQuestions[categoryID] ? systemMessages.newQuestions[categoryID] : '';
  const requestPayload = {
    model: "gpt-5.2",
    messages: [
      {
        role: "system",
        content: systemMessage,
      },
      {
        role: "user",
        content: additionalMessage + content,
      },
    ],
    functions: [
      {
        name: "createExercises",
        description:
          "get the example exercise or exercises with right, wrong and second answers",
        parameters: {
          type: "object",
          properties: {
            exercises: {
              type: "array",
              items: {
                type: "object",
                properties: {
                  exercise: {
                    type: "string",
                    description: "it's a new exercise",
                  },
                  correctAnswer: {
                    type: "string",
                    description: "it's a correct answer of the exercise",
                  },
                  wrongAnswers: {
                    type: "string",
                    description: "it's an object of wrong answers",
                  },
                  secondAnswer: {
                    type: "string",
                    description:
                      "it is a second answer or in other words calculation of the correct answer",
                  },
                },
              },
            },
          },
          required: ["exercises"],
        },
      },
    ],
    function_call: "auto",
    temperature: 1,
    max_completion_tokens: 4095,
    top_p: 1,
    frequency_penalty: 0,
    presence_penalty: 0,
  };
  try {
    return await openai.chat.completions.create(requestPayload);
  } catch (error) {
    return error;
  }
};

const createNewQuestionsMultistep = async (
  content,
  categoryID,
  questionsCount
) => {
  const glossary =
    systemMessages.newQuestions.mainTextMultistepFieldGlossary || "";
  const basePrompt = systemMessages.newQuestions.mainTextMultistep;
  const systemMessage =
    glossary + basePrompt.replace("{{COUNT}}", String(questionsCount));
  let additionalMessage = systemMessages.newQuestions[categoryID]
    ? systemMessages.newQuestions[categoryID]
    : "";
  const requestPayload = {
    model: "gpt-5.2",
    messages: [
      {
        role: "system",
        content: systemMessage,
      },
      {
        role: "user",
        content: additionalMessage + content,
      },
    ],
    functions: [
      {
        name: "createMultistepExercises",
        description:
          "Return exercises[]; each item MUST use these exact keys: exercise, correctAnswer, wrongAnswers (main step wrong options), answer_1 + wrong_answers_1, answer_2 + wrong_answers_2, answer_3 + wrong_answers_3, answer_4 + wrong_answers_4, secondAnswer. Do not use correctAnswer1 or wrongAnswers1 — use answer_1 and wrong_answers_1. Match wrong-array lengths to samples. secondAnswer = final result after last step only if examples use it.",
        parameters: multistepExerciseFunctionParameters,
      },
    ],
    function_call: "auto",
    temperature: 1,
    max_completion_tokens: 8192,
    top_p: 1,
    frequency_penalty: 0,
    presence_penalty: 0,
  };
  try {
    return await openai.chat.completions.create(requestPayload);
  } catch (error) {
    return error;
  }
};

const reviewNewQuestions = async (content, categoryID, questionsCount, generatedExercises) => {
  const basePrompt = systemMessages.newQuestions.mainText;
  const systemMessage = [
    basePrompt.replace("{{COUNT}}", questionsCount),
    "You are now a strict quality reviewer. I will provide generated exercises to review.",
    "Check every exercise for syntax accuracy and mathematical correctness.",
    "Fix incorrect correctAnswer values, malformed or duplicated wrongAnswers, and inconsistent secondAnswer.",
    "The wrongAnswers field must always be an array of strings.",
    "Ensure exactly " + questionsCount + " exercises are returned.",
    "Return only the final corrected data through function call."
  ].join(" ");
  const additionalMessage = systemMessages.newQuestions[categoryID]
    ? systemMessages.newQuestions[categoryID]
    : "";

  const userMessage = [
    additionalMessage + content,
    "",
    "Generated exercises to review and correct:",
    JSON.stringify({ exercises: generatedExercises }),
  ].join("\n");

  const requestPayload = {
    model: "gpt-5.2",
    messages: [
      { role: "system", content: systemMessage },
      { role: "user", content: userMessage },
    ],
    functions: [
      {
        name: "createExercises",
        description: "return the reviewed and corrected exercises",
        parameters: {
          type: "object",
          properties: {
            exercises: {
              type: "array",
              items: {
                type: "object",
                properties: {
                  exercise: {
                    type: "string",
                    description: "it's a new exercise",
                  },
                  correctAnswer: {
                    type: "string",
                    description: "it's a correct answer of the exercise",
                  },
                  wrongAnswers: {
                    type: "array",
                    items: { type: "string" },
                    description: "it's an array of wrong answers",
                  },
                  secondAnswer: {
                    type: "string",
                    description:
                      "it is a second answer or in other words calculation of the correct answer",
                  },
                },
              },
            },
          },
          required: ["exercises"],
        },
      },
    ],
    function_call: "auto",
    temperature: 0.2,
    max_completion_tokens: 4095,
    top_p: 1,
    frequency_penalty: 0,
    presence_penalty: 0,
  };
  try {
    return await openai.chat.completions.create(requestPayload);
  } catch (error) {
    return error;
  }
};

const reviewNewQuestionsMultistep = async (
  content,
  categoryID,
  questionsCount,
  generatedExercises
) => {
  const glossary =
    systemMessages.newQuestions.mainTextMultistepFieldGlossary || "";
  const basePrompt = systemMessages.newQuestions.mainTextMultistep;
  const systemMessage = [
    glossary + basePrompt.replace("{{COUNT}}", String(questionsCount)),
    "You are now a strict quality reviewer. I will provide generated exercises to review.",
    "Check every exercise for syntax accuracy and mathematical correctness.",
    "Fix incorrect correctAnswer values, malformed wrongAnswers arrays, and follow-up steps answer_1..answer_4 with wrong_answers_1..wrong_answers_4.",
    "When a step is used, the length of each wrong-answer array must match the corresponding step in the user's sample exercises (not a fixed count). Empty tail follow-up steps must use empty string for answer_k and [] for wrong_answers_k.",
    "Apply the chain rule: follow-up k+1 must be the natural next step after the correct choice at follow-up k; the app uses the previous step's correct answer as the visible line for the next step.",
    "secondAnswer: use an empty string when the topic examples use an empty second answer; otherwise set it only to the final result after the last MC step, never an intermediate.",
    "Ensure exactly " + questionsCount + " exercises are returned.",
    "Return only the final corrected data through function call.",
  ].join(" ");
  const additionalMessage = systemMessages.newQuestions[categoryID]
    ? systemMessages.newQuestions[categoryID]
    : "";

  const userMessage = [
    additionalMessage + content,
    "",
    "Generated exercises to review and correct:",
    JSON.stringify({ exercises: generatedExercises }),
  ].join("\n");

  const requestPayload = {
    model: "gpt-5.2",
    messages: [
      { role: "system", content: systemMessage },
      { role: "user", content: userMessage },
    ],
    functions: [
      {
        name: "createMultistepExercises",
        description:
          "Return reviewed exercises[] with exact keys: exercise, correctAnswer, wrongAnswers, answer_1..answer_4, wrong_answers_1..wrong_answers_4, secondAnswer (not correctAnswer1/wrongAnswers1).",
        parameters: multistepExerciseFunctionParameters,
      },
    ],
    function_call: "auto",
    temperature: 0.2,
    max_completion_tokens: 8192,
    top_p: 1,
    frequency_penalty: 0,
    presence_penalty: 0,
  };
  try {
    return await openai.chat.completions.create(requestPayload);
  } catch (error) {
    return error;
  }
};

const getImprovement = async (text, notHTML) => {
  let systemMessage = '';
  if (notHTML) {
    systemMessage = "Improve the given text. You can rephrase the text to make it more native and professional. Your provided text should replace the initial text. If the text is not clear to you, please return the same text."
  } else {
    systemMessage = "Improve the given text. You can rephrase the text to make it more native and professional. Your provided text should replace the initial text. Your provided text should be designed with simple HTML tags (only div, p, b, i, u, ul, li). If the text is not clear to you, please return the same text."
  }

  try {
    return await openaiDavo.chat.completions.create({
      model: "gpt-4o",
      messages: [
        {
          "role": "system",
          "content": systemMessage
        },
        {
          "role": "user",
          "content": text
        }
      ],
      temperature: 1.34,
      max_tokens: 4095,
      top_p: 0.7,
      frequency_penalty: 0,
      presence_penalty: 0,
    });
  } catch (error) {
    return error
  }
};

module.exports = {
  getSolution,
  getSolutionSeo,
  parseSolutionSeoResponse,
  getCategoryLesson,
  extractBodyHtml,
  stripHtml,
  truncateText,
  createNewQuestions,
  createNewQuestionsMultistep,
  reviewNewQuestions,
  reviewNewQuestionsMultistep,
  getImprovement,
  normalizeWrongAnswersList,
};
