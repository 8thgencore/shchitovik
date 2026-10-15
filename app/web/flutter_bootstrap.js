{{flutter_js}}
{{flutter_build_config}}

// Removes the loading indicator of index.html once the app is running.
_flutter.loader.load({
  onEntrypointLoaded: async (engineInitializer) => {
    const appRunner = await engineInitializer.initializeEngine();
    await appRunner.runApp();
    document.getElementById('loading')?.remove();
  },
});
