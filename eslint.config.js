import js from '@eslint/js';
import ts from 'typescript-eslint';
import eslintConfigPrettier from 'eslint-config-prettier';

export default [
  js.configs.recommended,
  ...ts.configs.recommended,
  eslintConfigPrettier,
  {
    ignores: ['dist/', '**/build/'],
  },
];
