---
usemathjax: true
layout: post
title: "Can Coding Agents Help Write Scientific Code Responsibly?"
date: 2025-10-17 5:00:00
background: /img/posts/coding-agents-responsibly-images/marcin-szmigiel-Oc3G2fDYSWs-unsplash.jpg
---

I’ve been experimenting with Claude Code to write research code for several months now. [When I last wrote about this](https://jorisbaan.nl/2025/07/09/thoughts-on-using-AI-for-scientific-research-and-software-engineering.html), I was worried that I wouldn't feel in control of my own code, and that bugs would creep in. But also for a general decline in my own (coding) expertise, and even in enjoying my work.

To my own surprise, I actually quite like it - although there is a trade-off. 

### How it works
Claude Code simply runs in a terminal window and needs permission to read/write certain files and execute certain shell commands (eg create a new file, run a python script, run a search query, install a package, etc). You can chat in the terminal and see Claude planning, reasoning, editing files, and executing shell commands in real-time, which takes a couple of seconds or minutes. I have PyCharm open next to it.
 

I started a new codebase from scratch for a new research project and used Claude from the start. This felt like a really nice alternative to finding an existing repo accompanying a published paper. In my experience, these seem useful in the short term but are often unreadable, incomplete, and sometimes even contains bugs. Starting from scratch gave me full control over the code and its design.

### Workflow: refine + Claude Code + code review

The workflow reminds me most of working in a team of software engineers. I first work out a high-level system architecture, potentially brainstorming with Claude, and then refine a new task, feature, bug fix, etc. 

A task shouldn’t be too small (changing a variable name), but also not too big (write or refactoring my entire codebase at once). An example task might be to create a simple generation pipeline or to implement LLM-as-a-judge evaluation with an external API. (I would describe these to Claude in much more detail.)

I ask Claude to present a plan, iteratively refine it “together”, and then let it execute. Proper version control is absolutely essential, since you want be able to clearly see any changes and easily revert them. 

I then carefully review each line of code as if it were a pull-request made by a team member. This really makes it feel like my own code. I either make changes manually or give Claude a list with desired changes. I often let Claude do a first review pass and check for bugs.


| ![](/img/posts/coding-agents-responsibly-images/claude_cli.png){: .responsive-image } |
|:--------------------------------------------------------------------------------------:|
|                            The CLI interface of Claude Code. There is another screenshot at the bottom of this post.                            
 |

### Mistakes

There sometimes are mistakes in the generated code. Still, overall it is of high quality. Besides, there will undoubtably be mistakes in my own code, at least during development. I think it’s crucial to be able to judge whether Claude’s code is good or bad, and have an intuition of where to expect issues (e.g., complicated indexing logic during batching). 

I found small ways to steer Claude towards better code, like linking a specific page of the official documentation in my instruction.

Interestingly, because it is so much easier and faster to write code, I noticed that I’m more inclined to use good software engineering practices and design my code such that minimizes the possibility for bugs. For example, unit and integration tests.

### Unit and integration tests

After working as an ML engineer I’ve always found it strange that we generally never write tests in NLP/AI research. To some extend this make sense: research code changes rapidly; you’re often writing it alone; writing and maintaining tests is time consuming; and it can be hard to write meaningful tests that either mock or run big, stochastic models. Still, I think it’s bad for reproducibility.

Creating - and particularly maintaining - unit/integration tests with Claude Code is so much faster. This gave me more confidence in my codebase. A very cool thing is that, since Claude can run anything in the terminal, it can run these tests too, iteratively improving its own code similar to how I would do it myself.

One caveat: tests still need to be designed and reviewed with care. Just saying “write tests for this script/function often results in a lot of tests that didn’t quite capture what was important to me. Similarly, just saying “fix these failing tests” makes Claude either adapt the test to the new code or vice versa, and the difference can be crucial. 

In this sense, tests can also give a false sense of security.

### Vibe coding non-crucial tools

This strategy so far is very hands-on, which I think is (at least for now) important for core research code. I wouldn’t feel comfortable using Claude to write core research code in a codebase that I’m not familiar with, or to create everything at once without breaking it up in smaller tasks that I carefully describe and review.

I used a different strategy to build a web interface in pure html/css/js to visualise individual records from a dataset with model generations, evaluation metrics and uncertainty metrics, including search and filtering to navigate. I let Claude build and maintain the entire tool through prompting alone - I guess I’d call this vibe coding - without looking at or changing single line of code. It works remarkably well.

This is a nice example of something extra that I wouldn’t have built without Claude. I feel comfortable not understanding the code since it’s not part of my experiments. 

### My overall experience

Surprisingly, I actually quite enjoyed this new process. I’m stuck less often; I still experience the joy of writing good code; I still feel on top of everything. 

However, there’s a trade-off. Letting Claude work on bigger, more complex tasks autonomously leads to faster progress, but also less control, understanding, and trust - so in the long run, perhaps less progress. It depends on the risk you’re willing to take and the extent to which you care about the specifics of the implementation and all the little choices involved.

Going from nothing to something, like adding new features in a fresh codebase, works like magic. Just like finding and fixing bugs, and asking language or framework related questions (stackoverflow style). It led to much faster experimentation and helpful tools. It’s somehow easier for me to be satisfied with code that I did design but didn’t write: I don’t get pulled into prematurely optimizing for elegance, generality or efficiency as much. It reduces cognitive effort not having to think about variable names or function structures, etc.

For more subtle, complex changes, and especially refactors, I sometimes spent more time correcting Claude than I would’ve needed to write it myself. That’s really annoying. Also, problems are often more complicated than I initially think, and working through them give a different perspective on the solution or even my end goal. Offloading this to a coding agent that autonomously decides how to tackle those problems is risky if the details matter (which they often do in research code).

I guess part of the skill of using a coding agent is to know how and when to use it.

### Productivity

Does it really make me more meaningfully productive? In this specific case of setting up a new codebase, it did feel that way. 

However, I could be fooling myself. For example, this [study](https://metr.org/blog/2025-07-10-early-2025-ai-experienced-os-dev-study/) found that experienced developers felt more productive using AI but were in fact slower. Perhaps coding agents give a “feeling of productivity” or “reduction of cognitive effort” rather than actually supporting more and faster long-term progress. Or perhaps it’s just the initial learning curve for these kind of tools - it’s hard to say.

### Conclusion

So, can coding agents help write scientific code responsibly? I think so, yes. But it’s up to the researcher to carefully design, review, adapt, and own the resulting code. I think you need to be able to write and understand everything yourself to be able to use it responsibly (and effectively) for complex tasks. To be able to recognize good from bad design/architecture/code/tests/etc, and spot mistakes.

I think it’s useful and fun as an AI researcher to use and understand these tools, and at least experiment with them, and I will continue to. However, I don’t think that, at least right now, it’s a magic bullet that will suddenly massively increase the quality or quantity of your research.

I still dislike sending my research code to a commercial company’s servers. Also, it's relatively affordable right now ($20/month), but pricing is bound to go up, which could make over reliance a (financial) problem, and coding agents difficult to access for researchers that can't afford it. And there’s of course the issue of the compute and energy footprint.

I’m still not sure what to think about increasingly autonomous coding agents without a human in the loop, like promises of these “fully autonomous AI scientists” that produce papers accepted at top tier conferences. 

Right now, coding agents somehow feel both like a radical change in how to write code, but also like just another tool.

|    ![](/img/posts/coding-agents-responsibly-images/claude_cli_implementing.png){: .responsive-image }    |
|:------------------------------------------------------------------------------:|
| After a few back-and-forths about the plan and giving my approval, Claude Code starts creating and editing files. There's too much text to show everything, so this is just a tiny snippet of the entire chat.
 | 
