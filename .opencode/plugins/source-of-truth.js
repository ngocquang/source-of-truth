/**
 * Source of Truth plugin for OpenCode.ai
 *
 * Registers the source-of-truth skills directory so OpenCode discovers the
 * skill (no symlinks needed). The skill itself activates automatically from
 * its description when a task touches a docs/ spec catalog — so this plugin
 * only needs to make the skill discoverable, not inject any bootstrap.
 */

import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const skillsDir = path.resolve(__dirname, '../../skills');

export const SourceOfTruthPlugin = async () => {
  return {
    // Inject the skills path into live config so OpenCode discovers the
    // source-of-truth skill without manual symlinks or config edits.
    config: async (config) => {
      config.skills = config.skills || {};
      config.skills.paths = config.skills.paths || [];
      if (!config.skills.paths.includes(skillsDir)) {
        config.skills.paths.push(skillsDir);
      }
    },
  };
};
