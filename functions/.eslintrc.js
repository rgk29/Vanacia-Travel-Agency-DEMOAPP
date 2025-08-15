module.exports = {
  root: true,
  env: {
    es6: true,
    node: true,
  },
  extends: [
    "eslint:recommended",
    "plugin:@typescript-eslint/recommended",
  ],
  parser: "@typescript-eslint/parser",
  parserOptions: {
    project: ["tsconfig.json"],
    sourceType: "module",
  },
  ignorePatterns: [
    "/lib/**/*",
    ".eslintrc.js"
  ],
  plugins: ["@typescript-eslint"],
  rules: {
    "indent": "off",
    "@typescript-eslint/indent": ["error", 2],
    "quotes": ["error", "double"],
    "comma-dangle": "off",
    "max-len": "off",
    "object-curly-spacing": "off",
    "keyword-spacing": ["error", { "before": true }],
    "import/no-unresolved": "off"
  },
};