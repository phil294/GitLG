module.exports = {
  projects: [
    './web',
    './src',
  ],
  settings: {
    "coffeesense.ignoredTypescriptErrorCodes": [
      7030, // Not all code paths return a value
    ],
  }
}
