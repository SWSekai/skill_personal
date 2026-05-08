const fs = require('fs');
const path = require('path');

const manifestPath = path.join('.sekai-workflow', 'manifest.json');
const manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));

if (manifest.skills) {
    manifest.skills.forEach(skill => {
        if (skill.files) {
            skill.files = skill.files.map(file => {
                if (!file.startsWith('skills/')) {
                    return 'skills/' + file;
                }
                return file;
            });
        }
    });
}

fs.writeFileSync(manifestPath, JSON.stringify(manifest, null, 2), 'utf8');
console.log('Updated manifest.json with new skill paths.');
