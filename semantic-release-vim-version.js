const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

module.exports = {
  prepare: (pluginConfig, { nextRelease, logger }) => {
    const version = nextRelease.version;
    logger.log(`Updating all files to version ${version}`);
    
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
    
    // Update package.json version
    const packagePath = path.join(process.cwd(), 'package.json');
    let packageContent = JSON.parse(fs.readFileSync(packagePath, 'utf8'));
    packageContent.version = version;
    fs.writeFileSync(packagePath, JSON.stringify(packageContent, null, 2) + '\n');
    logger.log('Updated package.json version');
    
    // Update package-lock.json by running npm install --package-lock-only
    try {
      execSync('npm install --package-lock-only', { stdio: 'pipe' });
      logger.log('Updated package-lock.json version');
    } catch (error) {
      logger.error('Failed to update package-lock.json:', error.message);
      throw error;
    }
  }
};