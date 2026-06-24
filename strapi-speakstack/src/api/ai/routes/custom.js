module.exports = {
  routes: [
    {
      method: "GET",
      path: "/ai/usage",
      handler: "ai.usage",
    },
    {
      method: "GET",
      path: "/ai/memory",
      handler: "ai.memory",
    },
    {
      method: "DELETE",
      path: "/ai/memory",
      handler: "ai.memory",
    },
    {
      method: "POST",
      path: "/ai/transcribe",
      handler: "ai.transcribe",
    },
    {
      method: "POST",
      path: "/ai/tutor",
      handler: "ai.tutor",
    },
    {
      method: "POST",
      path: "/ai/tts",
      handler: "ai.tts",
    },
    {
      method: "POST",
      path: "/ai/evaluate-session",
      handler: "ai.evaluateSession",
    },
  ],
};
