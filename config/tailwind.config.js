module.exports = {
  content: [
    './app/views/**/*.{erb,html}',
    './app/helpers/**/*.rb',
    './app/javascript/**/*.js',
    './app/components/**/*.{erb,html,rb}',
    './lib/components/**/*.{erb,html,rb}'
  ],
  theme: {
    extend: {}
  },
  plugins: []
}

/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './app/views/**/*.{erb,haml,html,slim}',
    './app/helpers/**/*.rb',
    './app/assets/stylesheets/**/*.css',
    './app/javascript/**/*.js',
    './config/initializers/**/*.rb',
    './lib/components/**/*.{rb,erb,haml,html,slim}'
  ],
  theme: {
    extend: {
      colors: {
        primary: {
          '50': '#f0f9ff',
          '100': '#e0f2fe',
          '200': '#bae6fd',
          '300': '#7dd3fc',
          '400': '#38bdf8',
          '500': '#0ea5e9',
          '600': '#0284c7',
          '700': '#0369a1',
          '800': '#075985',
          '900': '#0c4a6e',
          '950': '#082f49',
        },
        'naija-green': {
          DEFAULT: '#008751',
          '50': '#f0fdf4',
          '100': '#dcfce7',
          '200': '#bbf7d0',
          '300': '#86efac',
          '400': '#4ade80',
          '500': '#008751',
          '600': '#006d42',
          '700': '#005c37',
          '800': '#004a2d',
          '900': '#003d24',
        },
        'naija-amber': {
          DEFAULT: '#f59e0b',
          '50': '#fffbeb',
          '100': '#fef3c7',
          '200': '#fed7aa',
          '300': '#fdba74',
          '400': '#fb923c',
          '500': '#f59e0b',
          '600': '#d97706',
          '700': '#b45309',
          '800': '#92400e',
          '900': '#78350f',
        }
      }
    }
  },
  plugins: [
    require('@tailwindcss/forms'),
    require('@tailwindcss/aspect-ratio'),
    require('@tailwindcss/typography'),
    require('@tailwindcss/container-queries')
  ]
}
