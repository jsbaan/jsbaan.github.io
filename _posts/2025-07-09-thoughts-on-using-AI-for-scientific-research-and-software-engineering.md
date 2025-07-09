---
usemathjax: true
layout: post
title: "Thoughts on using AI for scientific research and software engineering"
date: 2025-07-09 5:00:00
background: /img/posts/thoughts-on-using-ai-images/sebastian-unrau-sp-p7uuT0tw-unsplash.jpg
---
As a PhD candidate doing AI research, and a former ML engineer, I am not sure what to think of the bombardment of new AI models and tools and if or how I should integrate them into my workflow. On the one hand, I am amazed and curious and excited to test them out. On the other hand, it’s overwhelming and I feel a certain pressure to use them, and a restlessness about (the future of) my way of working and the field at large.  

Since AI research is such an incredibly competitive field, it feels like I might put myself at a disadvantage in terms of productivity or even quality, but also by (not) developing the skillset and efficiency of working with AI. Skills that - whether I like it or not - I think are and will increasingly become important for AI researchers and engineers. 

On top of that, I feel like it’s my responsibility as a researcher to experiment with the latest AI systems from a “consumer perspective” to gain first-hand experience and understanding of the capabilities AI systems deployed and used in the real world.

Here are some thoughts after experimenting for a while. I’ll stick to my personal experience, rather than the impact of AI on society as a whole - which is another can of worms.


# Scientific research

I’ve used Claude or ChatGPT or Gemini to brainstorm about research questions, find relevant research papers, chat about a research paper, do initial dataset analyses (including writing python code), write prototyping code, help me navigate and understand new codebases, and more.

Sometimes, it’s incredibly impressive. For example, the dataset analysis was really good. I know that, since I manually did the analysis prior to asking ChatGPT to do it for me, and it came up with many of the same statistics and insights. Another example is finding related papers. After doing a literature review myself, I asked Gemini Deep Research to do the same, and it found many of the same papers, including a few that I did not find myself yet, while also missing a few others.

Learning about new software frameworks or languages by asking questions has also been quite useful. Asking it to approximate the costs of an LLM-as-a-judge evaluation for a particular dataset across different commercial platforms quickly helped me to make a decision. Brainstorming about research questions was fun, and really quite good, although it didn’t quite feel *actually* helpful to my research.

That last feeling is one that sticks. Most of the output is really insanely impressive, but I wonder if it has actually sped up my work, or improved its quality. Of course, this may very well change in the future if models get better and I get better at using them effectively. But for now, I’m left with these thoughts:

1. **I don’t trust it to take fully take over tasks without making mistakes.** Rigor is at the core of scientific research, and not knowing if or where errors creep in feels dangerous. This means I have to double check stuff, which diminishes productivity gains.
2. **It makes me think less deeply, have less context and feel less ownership.** This is an important one. As a (lead) researcher, I want to understand and be able to defend everything about a project: every line in the codebase, every part of the experimental setup and results, and every paragraph in the resulting paper. It feels like offloading part of the core research process to an AI assistant fundamentally conflicts with this. Of course there are lower-risk tasks like debugging, proof reading, quickly learning about a new framework, getting a rough overview of a new field or paper or idea, help with understanding a math equation or asking specific questions about a paper, etc. As long as I have the expertise to distinguish good answers from bad ones it will be fine. But in general, so far, I do feel that using AI for more “serious” research tasks risks thinking less deeply, becoming lazy and increasingly dependent. Even for more tedious tasks, like keeping up with new papers, doing this myself translates in knowledge and expertise about the contours of a field or topic; about the kind of things people are working on. Perhaps it’s precisely these things that can spark new ideas or connect existing ideas. A similar point was recently made by [Cal Newport](https://calnewport.com/does-ai-make-us-lazy/). 
3. **I don’t like sharing unpublished research data.** It just feels like a bad idea to share bits and pieces of my unpublished research with commercial companies and their research labs who store it for who knows how long and what purpose.
4. **Obviously, there are big questions around plagiarism and ownership.** I haven’t used AI such that I think it warrants (co)-authorship or acknowledgement, in part because I’d feel rather uncomfortable giving away such a degree of control to an AI system. But once you start integrating AI into your workflow more and more, the lines begin to blur.

# Software engineering & coding agents

So far, I have the impression that for software engineering all of the above is less of an issue - though still relevant. Software engineering is (1) more test driven, if only because research code is bound to change so quickly that writing tests adds overhead that’s often not worth it, (2) more team-based and collaborative, and (3) often has smaller, well defined tasks. I think this all contributes to easier integration of “AI teammates” in the workflow, for example by letting an AI agent prepare a PR based on a well defined ticket, or [Anthropic’s onboarding flow that uses Claude Code to get new employees up to speed](https://www.anthropic.com/engineering/claude-code-best-practices) while sparing the time of colleagues.

I have had several “this is insane” moments over the last couple of years, and Claude Code - a coding agent that integrates directly into the terminal - was one of them. I asked it to migrate my personal website to another framework. It researched what new framework to pick, installed the right packages, made a new git branch, and built the new website from scratch, all within 1-2 hours. After testing it locally, it was almost perfect but I made a list of things that still needed to be fixed, and it took about 15 minutes to fix all of them. It was really amazing to see it run commands in my terminal autonomously, fix bugs, rethink its approach, research stuff online, and even spin up a docker container at some point to get around compatibility issues. 

I didn’t deploy the website since my current one is fine, but if I had, it would still give me a slightly uncomfortable feeling to never have looked at (and therefore don’t fully understand) the code of my own website. I guess I’m both the type of person that likes to understand how things work under the hood, but also that likes to try out new technologies if they make me more effective.

Compared to the research tasks I described above, I really see a lot less problems with having an AI agent (re)build my website. Still, if I were still working as a software engineer right now, I think I would feel similarly uncomfortable about not understanding “my own” (AI agent) code changes, and my increasing reliance on it. It’s really a new and difficult balance.

# So, my thoughts…

So far: mixed feelings. Especially about using AI in the scientific research process. it may be that over time we will all start to rely more and more on AI assistants/agents, and be OK with offloading cognitive effort while sacrificing a bit of expertise, skill, context, and ownership. For now though, I’m not sure that I like that sacrifice.

I do think it’s incredibly useful as an AI researcher to step outside the realm of scientific papers/datasets and use AI systems as a consumer, since there’s a pretty big gap between the stuff I see in research papers, and the stuff I experience with commercial APIs/agents. Ignoring those completely doesn’t feel sustainable and paints an incomplete picture of the field and its progress.