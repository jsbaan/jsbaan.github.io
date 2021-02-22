---
usemathjax: true
layout: post
title: "News Recommendation at Scale"
subtitle: "How We Personalize News At DPG Media"
date: 2020-08-5 23:45:13 -0400
background: /img/posts/bayesian-dl-images/Untitled.png # '/img/posts/01.jpg'
---


Originally posted at [Medium](https://dpgmedia-engineering.medium.com/news-recommendation-at-scale-2ce03bbc4692)

With roughly a thousand news articles published by journalists at DPG Media every day, it is a challenge to bring the right articles to the right readers at the right time. An important role of newspapers is to optimally inform readers, balancing between providing news that interests readers, news that provides alternate views or opinions, and news that editors believe readers have to know about. Welcome to the world of news personalization.

News personalization is a very interesting space, both in terms of engineering and machine learning. It is also very socially relevant due to concerns about filter bubbles and privacy. In this blogpost I will talk about how we use machine learning at DPG Media to get the right content to the right users at the right time. There are many products in which personalization can materialize (e-mail, “for you” sections on websites, etc.). In this post I will discuss news recommendation in the form of personalized push notifications. This illustrates the core concept and currently runs in  production for some of our major news titles.

# Why is it hard?
News recommendation is an interesting problem for two reasons.
ML modeling: designing a recommender that understands both users and news articles, and is able to match them while taking into account goals such as relevancy, diversity and recency.
Scale: DPG Media is the largest Dutch/Belgian publisher with thousands of journalists producing high-quality content every day. Our users leave traces of their interactions with our products through an event stream with peak volumes around 100K events per second. A recommender must be fast enough to handle these loads in our production environment.

# So, News Recommendation...
Let’s dive right into it! There are several ways to go about news recommendation. Since it’s a recommendation task, the first thing that comes to mind is collaborative filtering. Collaborative filtering is based on how users interact with items. Given that user X has read a set of news articles, it makes sense to recommend an article that users with a similar reading history also interacted with. However, there is one big problem with collaborative filtering in the news domain. An important aspect of news is, perhaps unsurprisingly, the fact that it’s new. We therefore typically don’t have much information about interactions at the moment we would like to recommend an article. This is commonly referred to as the item cold-start problem. In particular, when sending personalized push notifications at the moment of publication, items have had no interactions at all.

# The core idea
Because of this cold-start problem, we went for a pure content-based approach. The core idea is very simple. A vector representation of a news article is concatenated to a vector representation of a user profile and fed to a classifier that predicts how well the two match. This approach opens up a huge playing field in which we can take advantage of exciting recent developments in Natural Language Processing (NLP) & representation learning, such as Google’s BERT or OpenAI’s GPT-2, to compute more expressive user and article embeddings. For the first iteration, however, we left all the heavy machinery on the shelf and started with a simple, scalable solution.

## … along with a few details
Article embeddings are defined as a TF-IDF weighted average over word2vec embeddings of all words in an article. User embeddings are simply the sum over the article embeddings in a user’s reading history. Whenever a news article is published, it enters our push pipeline, and we want to find interested users. As we have millions of users on our platforms, considering all users for every new article is infeasible. Instead, we filter based on recent reading activity and employ a simple trick to sample candidate users based on how often they recently opened personalized push-notifications. This provides a preference to users that recently interacted a lot with what we recommended. Besides huge computational gains, this also ensures that users who never open push messages slowly stop receiving them. Finally, we have a model (‘the scheduler’) that predicts whether an article should be recommended to a user immediately, or with a certain delay. This is based on the current time and the times at which a user usually consumes news.

# Cool, but does it work?
Looks like it! When comparing personalized push notifications to pushes sent by our editors, we see a factor 10 increase of users that open a push, based on millions of push notifications.

# Filter bubbles and diversity
A common conception about news recommendation is that it might create filter bubbles, in which users only receive recommendations that confirm their view. We take this very seriously and are currently experimenting with several diversity metrics. These metrics measure diversity along dimensions such as content (article embedding), author, brand, sentiment, recency, etc. Inspired by Maximum Marginal Relevance (MMR) and information gain, we model reading behavior by sequentially traversing a list of recommended articles and computing diversity between current and previous articles. The idea is that this mimics the way a user perceives the diversity of a recommendation based on previous reads or recommendations. Our goal is to first evaluate our recommender in terms of diversity, and then to use it as an objective function during training. Or perhaps as part of a post-processing step that re-ranks based on diversity.

In our current production systems, we don’t think that filter bubbles are prominent yet. The users that are exposed to our recommender only get a small fraction of their news diet through our systems. On average, our users receive only about 1 personalized push notification every 3 days. The rest of their news consumption on our platforms is not served through personalisation algorithms. In addition, we currently don’t personalize content cross-brand, which makes the primary ‘filter bubble’ for a given user his/her choice of a specific news platform or brand.

# What we are working on right now

As I mentioned before, what I am most excited about is to experiment with more recent state-of-the-art language models. The rise of transformers and large language models such as BERT have moved the field of NLP forward at an unprecedented rate. As our approach revolves around language-based user and item representations, I expect that we can make big strides using such architectures. In particular, I’m very excited about framing news recommendation as a masked language modeling (MLM) objective. In MLM, random words in a sentence are masked or replaced by other words. The task is then to reconstruct the original sentence. This results in a model that is capable of predicting likely next words given a context.

Check out this great blogpost by Jay Alammar to learn more about BERT and MLM.

MLM is a form of self-supervised learning that leverages unlabeled text to obtain rich, contextualized word representations. Interestingly, we could apply the same principle to reading behavior. Like sentences, reading is a sequential process. Unlike sentences, the basic units are articles instead of words. The model would learn to assign probabilities to articles given (part of) a user’s reading behavior as context. This idea was recently applied to several sequential recommendation tasks, such as movies, games or products. We are currently experimenting with this in the news domain with one of our interns.

Using BERT-based models with a MLM objective in production opens up a new can of worms, however: they are very computationally heavy. Luckily, this is something that the research community is actively working on, for example with DistilBERT.

# Conclusion
We’ll keep on improving the quality of our recommendations while taking into account relevancy, diversity and recency. Based on results for personalized push notifications it looks like we are on a good way. Personally, I’m looking forward to experimenting with more recent representation learning model architectures, as well as deploying models in other personalization products.

If you have questions, don’t hesitate to get in touch! Also, a big shout out to the rest of the news personalization team for their awesome work, making everything I discussed possible!
