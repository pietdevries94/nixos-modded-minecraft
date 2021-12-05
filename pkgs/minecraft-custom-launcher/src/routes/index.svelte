<script lang="ts">
	import { Command } from '@tauri-apps/api/shell';

	let commandOutput = '';
	function addToOutput(str: string) {
		commandOutput += str + '\n';
	}

	async function openMC() {
		const command = new Command(
			'node',
			'/home/piet/Projects/Nix/nixos-modded-minecraft/pkgs/minecraft-custom-launcher/src-backend/index.mjs'
		);
		command.on('close', (data) => {
			console.log(`command finished with code ${data.code} and signal ${data.signal}`);
		});
		command.on('error', (error) => addToOutput(`command error: "${error}"`));
		command.stdout.on('data', (line) => addToOutput(`command stdout: "${line}"`));
		command.stderr.on('data', (line) => addToOutput(`command stderr: "${line}"`));

		const child = await command.spawn();
		addToOutput('pid:' + child.pid);
	}
</script>

<div class="container">
	<button on:click={openMC}>Open Minecraft</button>
	<pre>{commandOutput}</pre>
</div>

<style>
	.container {
		margin: 0;
		min-height: calc(100vh - 20px);
		background-color: black;
		color: white;
	}
</style>
