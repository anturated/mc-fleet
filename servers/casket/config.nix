{
  type = "cf";
  slug = "nightfallcraft-the-casket-of-reveries";

  addMods = ''
    chunky-pregenerator-forge
  '';
  removeMods = ''
    chat-plus
    clear-water
    domestication-innovation-whitelist
    simple-bedrock-model
  '';

  docker.java = 17;
  server.motd = "Genshin Impact™";
}
