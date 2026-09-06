---
description: Expand a terse prompt into a fuller one, with bracketed assumptions and notes, ready to copy
argument-hint: <prompt to expand>
---

Expand the prompt at the end of this message into a fuller, sharper prompt. Do not answer the prompt itself.

## How to expand

Work through these in order, but only add what earns its place. A three-line request should become a paragraph, not a page.

1. **Intent.** State the underlying goal in one sentence. If the literal request and the likely goal differ (I asked for a summary but probably want a decision), expand toward the goal and say so in your notes.
2. **Context.** Add the background the model needs and can't infer: who this is for, what it feeds into, what already exists, what's been tried. Where you don't know, insert a placeholder like [audience: board / customer / myself] rather than guessing.
3. **Constraints.** Length, format, tone, language, things to avoid, hard requirements. Convert vague adjectives ("good", "clean", "concise") into something checkable.
4. **Success criteria.** What would make the output excellent versus merely acceptable? If I haven't said, propose one or two criteria and mark them as proposals.
5. **Reasoning and process.** If the task benefits from it, ask the model to think first (list assumptions, consider alternatives, check its own work) before producing the answer. Skip this for simple tasks.
6. **Examples and anti-examples.** If a small example of the desired output or a common failure mode would sharpen the request, add one. Keep it short.
7. **Output format.** Specify structure only if it matters. Default to prose unless the content is genuinely multi-part.

## Rules

- Preserve my voice and any specific phrasing, names, or numbers I used.
- Do not invent facts, figures, or preferences. Every assumption goes in [brackets] inside the prompt so I can fill it in or delete it.
- Do not add generic filler ("Please be thorough and accurate"). Every sentence must change what the model would do.
- Do not pad short tasks. If the original prompt is already good, say so and make only minimal edits.
- If the request is ambiguous in a way that would send the model down two very different paths, write the expanded prompt for the most likely path and list the alternative in your notes.

## Output

Return exactly this:

**Expanded prompt** (the rewritten prompt in a code block, ready to copy)

**Notes**

- Assumptions I made (each maps to a [bracket] above)
- What I inferred about the goal, if different from the literal ask
- One or two things you might add that I left out because I wasn't sure they applied

Keep the notes under 120 words.

Here is the prompt to expand:

$ARGUMENTS
