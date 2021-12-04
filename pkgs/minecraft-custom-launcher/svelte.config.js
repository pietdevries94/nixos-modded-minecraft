import preprocess from 'svelte-preprocess';
import adapter from '@sveltejs/adapter-static';

/** @type {import('@sveltejs/kit').Config} */
const config = {
	// Consult https://github.com/sveltejs/svelte-preprocess
	// for more information about preprocessors
	preprocess: preprocess(),

	kit: {
		adapter: adapter({
			pages: 'build',
			assets: 'build',
			fallback: null
		}),
		ssr: false,
		// hydrate the <div id="svelte"> element in src/app.html
		target: '#svelte',
		files: {
			template: 'src/app.html'
		}
	}
};

export default config;
