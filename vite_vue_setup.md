## Create Vite App

```bash
npm init @vitejs/app project-name
```

## Install Tailwind + dependencies

```bash
npm install -D tailwindcss@latest postcss@latest autoprefixer@latest
```

## Install ESLint + Prettier

```bash
npm install --save-dev eslint prettier eslint-plugin-vue eslint-config-prettier
```

## Install Vue Router

```bash
npm install vue-router@4
```

## Install Vuex

```bash
npm install vuex@next --save
```

> .eslintrc.js:

```javascript
module.exports = {
  extends: ["plugin:vue/vue3-essential", "prettier"],
  rules: {
    // override/add rules settings here, such as:
    "vue/no-unused-vars": "error",
  },
};
```

> .prettierrc.js:

```javascript
module.exports = {
  semi: false,
  tabWidth: 4,
  useTabs: false,
  printWidth: 80,
  endOfLine: "auto",
  singleQuote: true,
  trailingComma: "es5",
  bracketSpacing: true,
  arrowParens: "always",
};
```
