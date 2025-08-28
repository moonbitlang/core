---
mode: agent
model: GPT-4o
description: Review the consistency between APIs
---

Your goal is to review the consistency between similar APIs. Ask for the type
names (at least 2) if not provided.

Find the definition of the type, figure out the directory it locates, and review the `pkg.generated.mbti` file.

**Criteria**

1. Clarity and readability of the interface definitions.
2. Consistency in naming conventions and structure.
3. Usability and functionality.

**Guidelines**

1. Only keep necessary APIs, such as those can only be defined internally to
   achieve the best performance.
2. Follow the existing naming convention of other programming language standard
   libraries for familiarity, but prioritize the consistency.

Be specific on the review. Point out the API that is problematic, together with
arguments, and suggested improvements.
