const fs = require('fs');
const path = require('path');
const os = require('os');
const { execSync } = require('child_process');

const PROJECT_ROOT = process.cwd();
const RULES_SOURCE = path.join(PROJECT_ROOT, '.sekai-workflow', 'rules', 'CORE.md');
const SKILLS_SOURCE = path.join(PROJECT_ROOT, '.sekai-workflow', 'skills');

const RULES_TARGETS = [
    'CLAUDE.md',
    'GEMINI.md',
    '.cursorrules'
];

const CLAUDE_SKILLS_TARGET = path.join(PROJECT_ROOT, '.claude', 'skills');
const HOOKS_SOURCE = path.join(PROJECT_ROOT, '.sekai-workflow', 'hooks');
const CLAUDE_HOOKS_TARGET = path.join(PROJECT_ROOT, '.claude', 'hooks');

function createSymlink(source, target, type = 'file') {
    if (fs.existsSync(target)) {
        const stats = fs.lstatSync(target);
        if (stats.isSymbolicLink()) {
            fs.unlinkSync(target);
        } else {
            const backup = target + '.bak';
            console.log(`Backing up existing ${target} to ${backup}`);
            if (fs.existsSync(backup)) {
                fs.rmSync(backup, { recursive: true, force: true });
            }
            fs.renameSync(target, backup);
        }
    }

    const targetDir = path.dirname(target);
    if (!fs.existsSync(targetDir)) {
        fs.mkdirSync(targetDir, { recursive: true });
    }

    try {
        if (os.platform() === 'win32') {
            if (type === 'dir') {
                fs.symlinkSync(source, target, 'junction');
                console.log(`Created Junction: ${target} -> ${source}`);
            } else {
                try {
                    fs.symlinkSync(source, target, 'file');
                    console.log(`Created Symlink: ${target} -> ${source}`);
                } catch (symlinkErr) {
                    // Fallback to Hard Link for files on Windows if Symlink fails (EPERM)
                    fs.linkSync(source, target);
                    console.log(`Created Hard Link: ${target} -> ${source}`);
                }
            }
        } else {
            fs.symlinkSync(source, target);
            console.log(`Created symlink: ${target} -> ${source}`);
        }
    } catch (err) {
        console.error(`Failed to link ${target}: ${err.message}`);
        if (type === 'file') {
            fs.copyFileSync(source, target);
            console.log(`Fallback: Copied ${source} to ${target}`);
        }
    }
}

console.log('--- Synchronizing Agent Rules & Skills ---');

// 1. Sync Rules
RULES_TARGETS.forEach(targetName => {
    const targetPath = path.join(PROJECT_ROOT, targetName);
    createSymlink(RULES_SOURCE, targetPath, 'file');
});

// 2. Sync Skills
createSymlink(SKILLS_SOURCE, CLAUDE_SKILLS_TARGET, 'dir');

// 3. Sync Hooks
if (fs.existsSync(HOOKS_SOURCE)) {
    createSymlink(HOOKS_SOURCE, CLAUDE_HOOKS_TARGET, 'dir');
}

console.log('--- Sync Complete ---');
