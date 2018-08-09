const { mix } = require('laravel-mix')

mix.js('src/index.js', 'dist/dom-factory.js')

mix.webpackConfig({
  output: {
    library: 'domFactory',
    libraryTarget: 'umd'
  }
})