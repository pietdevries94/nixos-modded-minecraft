import { Client } from 'minecraft-launcher-core';
const launcher = new Client();
import * as msmc from 'msmc';
import fetch from 'node-fetch';
//msmc's testing enviroment sometimes runs into this issue that it can't load node fetch
msmc.setFetch(fetch);
msmc
	.fastLaunch('raw', (update) => {
		//A hook for catching loading bar events and errors, standard with MSMC
		console.log('CallBack!!!!!');
		console.log(update);
	})
	.then((result) => {
		//Let's check if we logged in?
		if (msmc.errorCheck(result)) {
			console.log(result.reason);
			return;
		}
		//If the login works
		const opts = {
			clientPackage: null,
			// Pulled from the Minecraft Launcher core docs , this function is the star of the show
			authorization: msmc.getMCLC().getAuth(result),
			root: './minecraft',
			version: {
				number: '1.17.1',
				type: 'release'
			},
			memory: {
				max: '6G',
				min: '4G'
			}
		};
		console.log('Starting!');
		// @ts-expect-error wrong type
		launcher.launch(opts);

		launcher.on('debug', (e) => console.log(e));
		launcher.on('data', (e) => console.log(e));
	})
	.catch((reason) => {
		//If the login fails
		console.log('We failed to log someone in because : ' + reason);
	});
