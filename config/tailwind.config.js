/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './app/views/**/*.{erb,html,rb}',
    './app/helpers/**/*.rb',
    './app/assets/stylesheets/**/*.css',
    './app/javascript/**/*.js'
  ],
  darkMode: 'class', // or 'media' based on preference
  theme: {
    extend: {
      fontFamily: {
        sans: ['Inter', 'ui-sans-serif', 'system-ui', 'sans-serif'],
        heading: ['Poppins', 'ui-sans-serif', 'system-ui', 'sans-serif'],
      },
      colors: {
        // Nigerian flag colors and variations
        'naija-green': {
          50: '#f0fdf4',
          100: '#dcfce7',
          200: '#bbf7d0',
          300: '#86efac',
          400: '#4ade80',
          500: '#22c55e', // Main green from Nigerian flag
          600: '#16a34a',
          700: '#15803d',
          800: '#166534',
          900: '#14532d',
          950: '#052e16',
        },
        'naija-white': {
          DEFAULT: '#ffffff',
          dark: '#f8fafc',
        },
        // Accent colors for a vibrant forum
        'naija-amber': {
          300: '#fcd34d',
          400: '#fbbf24',
          500: '#f59e0b', // Niger River inspired
          600: '#d97706',
        },
        'naija-red': {
          400: '#f87171',
          500: '#ef4444', // Accent for important elements
          600: '#dc2626',
        },
        'naija-purple': {
          400: '#a78bfa',
          500: '#8b5cf6', // Royal purple for premium features
          600: '#7c3aed',
        },
        // Additional cultural colors
        'palm': {
          400: '#84cc16', // Palm oil/leaf inspired
          500: '#65a30d',
          600: '#4d7c0f',
        },
        'clay': {
          400: '#fb923c', // Nigerian clay/earth tones
          500: '#f97316',
          600: '#ea580c',
        },
        'kente': {
          300: '#ffd700', // Gold kente cloth inspired
          400: '#eab308',
          500: '#ca8a04',
        }
      },
      borderRadius: {
        'lg': '0.625rem',
        'xl': '1rem',
        '2xl': '1.5rem',
        '3xl': '2rem',
      },
      boxShadow: {
        'soft': '0 2px 15px -3px rgba(0, 0, 0, 0.07), 0 10px 20px -2px rgba(0, 0, 0, 0.04)',
        'card': '0 7px 20px 0 rgba(0, 0, 0, 0.12)',
        'nav': '0 2px 10px 0 rgba(0, 0, 0, 0.05)',
      },
      spacing: {
        '72': '18rem',
        '84': '21rem',
        '96': '24rem',
        '128': '32rem',
      },
      typography: (theme) => ({
        DEFAULT: {
          css: {
            maxWidth: '65ch',
            color: theme('colors.gray.800'),
            a: {
              color: theme('colors.naija-green.600'),
              '&:hover': {
                color: theme('colors.naija-green.500'),
              },
            },
            h1: {
              fontFamily: theme('fontFamily.heading'),
              fontWeight: '700',
            },
            h2: {
              fontFamily: theme('fontFamily.heading'),
              fontWeight: '600',
            },
            h3: {
              fontFamily: theme('fontFamily.heading'),
              fontWeight: '600',
            },
          },
        },
        dark: {
          css: {
            color: theme('colors.gray.300'),
            a: {
              color: theme('colors.naija-green.400'),
              '&:hover': {
                color: theme('colors.naija-green.300'),
              },
            },
          },
        },
      }),
    },
  },
  plugins: [
    require('@tailwindcss/typography'),
    require('@tailwindcss/forms'),
    require('@tailwindcss/aspect-ratio'),
    require('@tailwindcss/line-clamp'),
  ],
}

