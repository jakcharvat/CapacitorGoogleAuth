await Bun.build({
  entrypoints: ['src/index.ts'],
  outdir: './dist',
  sourcemap: 'linked',
  minify: true,
  external: ['@capacitor/core'],
});

// Make ts lsp happy
export {};
