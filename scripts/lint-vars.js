#!/usr/bin/env node
// lint-vars.js — Reject single-letter variable declarations (except loop iterators).
// Usage: node scripts/lint-vars.js src/
// Exit code 1 if violations found. Designed for CI pre-push checks.

const fs = require('fs');
const path = require('path');

const dir = process.argv[2] || 'src';
const ITERATOR_PATTERN = /^\s*for\s+[a-zA-Z_]\s*[,=]/;
const BAD_LOCAL = /^\s*local\s+([a-zA-Z])\s*=/;
const ALLOWED_ITERATORS = new Set(['_', 'i', 'j', 'k']);

let violations = 0;

function scan(filePath) {
    const lines = fs.readFileSync(filePath, 'utf8').split('\n');
    lines.forEach((line, idx) => {
        // Skip loop iterators — for i, for j, for k are fine
        if (ITERATOR_PATTERN.test(line)) return;
        const match = line.match(BAD_LOCAL);
        if (match && !ALLOWED_ITERATORS.has(match[1])) {
            const rel = path.relative(process.cwd(), filePath);
            console.error(`  ${rel}:${idx + 1}: single-letter var '${match[1]}' → ${line.trim()}`);
            violations++;
        }
    });
}

function walk(dir) {
    for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
        const full = path.join(dir, entry.name);
        if (entry.name === 'love2d4me' || entry.name === 'node_modules') continue;
        if (entry.isDirectory()) walk(full);
        else if (entry.name.endsWith('.lua')) scan(full);
    }
}

walk(dir);

if (violations > 0) {
    console.error(`\n${violations} single-letter variable(s) found. Use descriptive names.`);
    process.exit(1);
} else {
    console.log('No single-letter variables found.');
}
