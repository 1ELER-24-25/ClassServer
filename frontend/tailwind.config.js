/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./src/**/*.{js,jsx,ts,tsx}",
    "./public/index.html",
  ],
  theme: {
    extend: {
      colors: {
        primary: '#2563EB',    // blå
        secondary: '#DC2626',   // rød
        background: '#F8FAFC',
        text: '#1E293B',
      },
      borderRadius: {
        DEFAULT: '8px',
      },
      borderWidth: {
        DEFAULT: '2px',
      },
      boxShadow: {
        DEFAULT: '0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06)',
      },
    },
  },
  plugins: [],
} 