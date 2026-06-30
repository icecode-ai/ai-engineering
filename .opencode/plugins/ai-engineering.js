import path from "path";
import fs from "fs";
import {fileURLToPath} from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '../../');
const SKILLS_DIR = path.join(ROOT, 'skills');
const COMMANDS_DIR = path.join(ROOT, 'commands');

const parseFrontmatter = (md) => {
    const match = md.match(/^---\n([\s\S]*?)\n---\n([\s\S]*)$/);
    if (!match) {
        return {
            frontmatter: {}, body: md
        }
    }

    const frontmatter = {};
    const body = match[2];
    for (const line of match[1].split('\n')) {
        const colonIdx = line.indexOf(':');
        if (colonIdx > 0) {
            const key = line.slice(0, colonIdx).trim();
            const value = line.slice(colonIdx + 1).trim().replace(/^["']|["']$/g, '');
            frontmatter[key] = value;
        }
    }

    return {frontmatter, body};
}

export const AiCommandsPlugin = async () => ({
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
    },
});