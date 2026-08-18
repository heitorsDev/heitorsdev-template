import js from "@eslint/js";
import tseslint from "typescript-eslint";

export default tseslint.config(
  {
    ignores: ["node_modules/**", "dist/**"],
  },
  js.configs.recommended,
  ...tseslint.configs.recommendedTypeChecked,
  {
    files: ["**/*.ts"],
    languageOptions: {
      parserOptions: {
        projectService: true,
        tsconfigRootDir: import.meta.dirname,
      },
    },
  },
  {
    // `node:test`'s top-level `test()` returns a promise nobody awaits — that's
    // the intended usage, not a floating promise.
    files: ["**/*.test.ts"],
    rules: {
      "@typescript-eslint/no-floating-promises": "off",
    },
  },
  {
    // Config files stay plain JS and out of the type-aware program.
    files: ["**/*.js"],
    extends: [tseslint.configs.disableTypeChecked],
  },
);
