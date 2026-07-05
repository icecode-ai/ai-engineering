import path from "path";
import fs from "fs";
import {fileURLToPath} from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '../../');
const SKILLS_DIR = path.join(ROOT, 'skills');
const COMMANDS_DIR = path.join(ROOT, 'commands');
const AGENTS_DIR = path.join(ROOT, 'agents');

const parseFrontmatter = (md) => {
    const match = md.match(/^---\n([\s\S]*?)\n---\n([\s\S]*)$/);
    if (!match) {
        return {
            frontmatter: {}, body: md
        }
    }

    const frontmatter = {};
    const body = match[2];
    const lines = match[1].split('\n');

    let i = 0;
    while (i < lines.length) {
        const line = lines[i];
        if (!line.trim()) {
            i++;
            continue;
        }

        const colonIdx = line.indexOf(':');
        if (colonIdx <= 0) {
            i++;
            continue;
        }

        const key = line.slice(0, colonIdx).trim();
        const rawValue = line.slice(colonIdx + 1).trim();

        if (rawValue === '>-' || rawValue === '>' || rawValue === '|-' || rawValue === '|') {
            const isFolded = rawValue.startsWith('>');
            const blockLines = [];
            let indent = null;
            i++;
            while (i < lines.length) {
                const blockLine = lines[i];
                if (blockLine === '') {
                    blockLines.push('');
                    i++;
                } else if (/^\s+/.test(blockLine)) {
                    if (indent === null) {
                        indent = blockLine.match(/^\s*/)[0].length;
                    }
                    blockLines.push(blockLine.slice(indent));
                    i++;
                } else {
                    break;
                }
            }

            if (isFolded) {
                const paragraphs = [];
                let current = [];
                for (const bl of blockLines) {
                    if (bl.trim() === '') {
                        if (current.length > 0) {
                            paragraphs.push(current.join(' '));
                            current = [];
                        }
                    } else {
                        current.push(bl.trim());
                    }
                }
                if (current.length > 0) {
                    paragraphs.push(current.join(' '));
                }
                frontmatter[key] = paragraphs.join('\n').trim();
            } else {
                frontmatter[key] = blockLines.join('\n').trim();
            }
        } else {
            frontmatter[key] = rawValue.replace(/^["']|["']$/g, '');
            i++;
        }
    }

    return {frontmatter, body};
}

export const AiEngineeringPlugin = async () => ({
    config: async (config) => {
        config.skills = config.skills || {};
        config.skills.paths = config.skills.paths || [];
        if (!config.skills.paths.includes(SKILLS_DIR)) {
            config.skills.paths.push(SKILLS_DIR);
        }

        config.command = config.command || {};

        if (fs.existsSync(COMMANDS_DIR)) {
            for (const file of fs.readdirSync(COMMANDS_DIR)) {
                if (!file.endsWith('.md')) continue;

                const filePath = path.join(COMMANDS_DIR, file);
                const {frontmatter, body} = parseFrontmatter(
                    fs.readFileSync(filePath, 'utf8'),
                );

                const name = file.replace(/\.md$/, '');
                config.command[name] = {
                    template: body,
                    ...(frontmatter.description ? {description: frontmatter.description} : {}),
                    ...(frontmatter.agent ? {agent: frontmatter.agent} : {}),
                    ...(frontmatter.model ? {model: frontmatter.model} : {}),
                };
            }
        }

        if (fs.existsSync(AGENTS_DIR)) {
            config.agent = config.agent || {};

            for (const file of fs.readdirSync(AGENTS_DIR)) {
                if (!file.endsWith('.md')) continue;

                const filePath = path.join(AGENTS_DIR, file);
                const {frontmatter, body} = parseFrontmatter(
                    fs.readFileSync(filePath, 'utf8'),
                );

                const name = file.replace(/\.md$/, '');
                config.agent[name] = {
                    description: frontmatter.description || '',
                    prompt: body,
                    mode: frontmatter.mode || 'subagent',
                    ...(frontmatter.model ? {model: frontmatter.model} : {}),
                    ...(frontmatter.temperature ? {temperature: parseFloat(frontmatter.temperature)} : {}),
                    ...(frontmatter.hidden !== undefined ? {hidden: frontmatter.hidden === 'true'} : {}),
                };
            }
        }
    },
});