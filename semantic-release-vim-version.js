const fs = require('fs');
const path = require('path');

module.exports = {
  prepare: (pluginConfig, { nextRelease, logger }) => {
    const version = nextRelease.version;
    logger.log(`Updating vim plugin version to ${version}`);
    
    // Update plugin/mdoutline.vim version comment and variable
    const pluginPath = path.join(process.cwd(), 'plugin/mdoutline.vim');
    let pluginContent = fs.readFileSync(pluginPath, 'utf8');
    
    // Update version comment
    pluginContent = pluginContent.replace(
      /^" Version: .+$/m,
      `" Version: ${version}`
    );
    
    // Update version variable
    pluginContent = pluginContent.replace(
      /let g:mdoutline_version = '.+'/,
      `let g:mdoutline_version = '${version}'`
    );
    
    fs.writeFileSync(pluginPath, pluginContent);
    logger.log('Updated plugin/mdoutline.vim version');
  }
};