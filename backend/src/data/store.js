import {
  mkdir,
  readFile,
  rename,
  writeFile,
} from 'node:fs/promises';

import { dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

function clone(value) {
  return structuredClone(value);
}

export class JsonStore {
  constructor(file) {
    this.file =
      file instanceof URL
        ? fileURLToPath(file)
        : file;

    this.data = null;
    this.writeQueue = Promise.resolve();
  }

  async init(seedData) {
    try {
      const fileContent = await readFile(
        this.file,
        'utf8',
      );

      this.data = JSON.parse(fileContent);
    } catch (error) {
      if (error.code !== 'ENOENT') {
        throw error;
      }

      this.data = clone(seedData);
      await this.save();
    }

    return this;
  }

  snapshot() {
    if (!this.data) {
      throw new Error(
        'Store has not been initialized.',
      );
    }

    return clone(this.data);
  }

  async update(mutator) {
    const result = await mutator(this.data);

    await this.save();

    return clone(result);
  }

  async save() {
    this.writeQueue = this.writeQueue.then(
      async () => {
        await mkdir(dirname(this.file), {
          recursive: true,
        });

        const temporaryFile = `${this.file}.tmp`;

        await writeFile(
          temporaryFile,
          `${JSON.stringify(this.data, null, 2)}\n`,
          'utf8',
        );

        await rename(
          temporaryFile,
          this.file,
        );
      },
    );

    return this.writeQueue;
  }
}

export class MemoryStore {
  constructor(seedData) {
    this.data = clone(seedData);
  }

  snapshot() {
    return clone(this.data);
  }

  async update(mutator) {
    const result = await mutator(this.data);

    return clone(result);
  }
}