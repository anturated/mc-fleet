{
  type = "cf";
  slug = "nightfallcraft-the-casket-of-reveries";
  version = "1.20.1";

  addMods = ''
    chunky-pregenerator-forge
  '';
  removeMods = ''
    chat-plus
    clear-water
    domestication-innovation-whitelist
    simple-bedrock-model
  '';

  server.motd = "Genshin Impact™";
}
