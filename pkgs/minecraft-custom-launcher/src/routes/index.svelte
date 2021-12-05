<script lang="ts">
	import { Command } from '@tauri-apps/api/shell';
	async function openMC() {
		const command = new Command(
			'node',
			'/home/piet/Projects/Nix/nixos-modded-minecraft/pkgs/minecraft-custom-launcher/src-backend/index.mjs'
		);
		command.on('close', (data) => {
			console.log(`command finished with code ${data.code} and signal ${data.signal}`);
		});
		command.on('error', (error) => console.error(`command error: "${error}"`));
		command.stdout.on('data', (line) => console.log(`command stdout: "${line}"`));
		command.stderr.on('data', (line) => console.log(`command stderr: "${line}"`));

		const child = await command.spawn();
		console.log('pid:', child.pid);
	}
</script>

<button on:click={openMC}>Open Minecraft</button>
