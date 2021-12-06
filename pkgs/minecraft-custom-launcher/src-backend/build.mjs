import esbuild from 'esbuild';

esbuild
	.build({
		entryPoints: ['index.ts'],
		outfile: 'dist/index.js',
		bundle: true,
		plugins: [],
		platform: 'node',
		external: ['electron']
	})
	.then(() => console.log('⚡ Done'))
	.catch(() => process.exit(1));
