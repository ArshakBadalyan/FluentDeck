module.exports = {
  routes: [
    {
      method: "GET",
      path: "/mobile-app-policy-public",
      handler: "mobile-app-policy.publicPolicy",
      config: {
        auth: false,
      },
    },
  ],
};
