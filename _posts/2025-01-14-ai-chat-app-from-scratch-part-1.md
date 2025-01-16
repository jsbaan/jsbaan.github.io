---
usemathjax: true
layout: post
title: "Designing, Building & Deploying an AI Chat App from Scratch (Part 1)"
subtitle: "Microservices Architecture and Local Development"
date: 2025-01-14 9:00:00
background: /img/posts/ai-app-from-scratch-images/part-1-building-unsplash-image.jpeg
---
# Introduction
The aim of this project is to learn about the fundamentals of modern, scalable web applications by designing, building and deploying an AI-powered chat app from scratch. We won’t use fancy frameworks or commercial platforms like ChatGPT. This will provide a better understanding of how real-world systems may work under the hood, and give us full control over the language model, infrastructure, data and costs. The focus will be on engineering, backend and cloud deployment, rather than the language model or a fancy frontend.

This is part 1. We will design and build a cloud-native app with several APIs, a database, private network, reverse proxy, and simple user interface with sessions. Everything runs on our local computer. In [part 2](https://jorisbaan.nl/2025/01/14/ai-chat-app-from-scratch-part-2.html), we will deploy our application to a cloud platform like AWS, GCP or Azure with a focus on scalability so actual users can reach it over the internet. Here is a quick demo.


|                                                                                                                            ![](/img/posts/ai-app-from-scratch-images/chat_demo.gif){: width="700" }                                                                                                                             |
|:-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------:|
| A quick demo of the app. We start a new chat, come back to that same chat, and start another chat. We will now build this app locally and make it available at localhost. 
 |


You can find the codebase at [https://github.com/jsbaan/ai-app-from-scratch](https://github.com/jsbaan/ai-app-from-scratch). Throughout this post I will link to specific lines of code with this hyperlink robot [🤖](https://github.com/jsbaan/ai-app-from-scratch) (try it!)

## Microservices and APIs

Modern web applications are often built using microservices - small, independent software components with a specific role. Each service runs in its own Docker container - an isolated environment independent of the underlying operating system and hardware. Services communicate with each other over a network using REST APIs. 

You can think of a REST API as the interface that defines how to interact with a service by defining *endpoints* - specific URLs that represent the possible resources or actions, formatted like http://hostname:port/endpoint-name. Endpoints, also called paths or routes, are accessed with HTTP requests that can have various types like GET to retrieve data or POST to create data. Parameters can be passed in the URL itself or in the request body or header.

# Architecture
Let’s make this more concrete. We want a web page where users can chat with a language model and come back to their previous chats. Our architecture will look like this: 


|                   ![](/img/posts/ai-app-from-scratch-images/local_architecture.png){: width="700" }                   |
|:---------------------------------------------------------------------------------------------------------------------:|
| Local architecture of the app. Each service runs in its own Docker container and communicates over a private network. 
 |

The above architecture diagram shows how a user’s HTTP request to localhost on the left flows through the system. We will discuss and set up each individual service, starting with the backend services on the right. Finally, we discuss communication, networking and container orchestration.  

The structure of this post follows the components in our architecture (click to jump to the section):
1. [**Language model API**](#1).  A llama.cpp language model inference server running the quantized Qwen2.5-0.5B-Instruct model [🤖](https://github.com/jsbaan/ai-app-from-scratch/tree/main/lm-api).
2. [**PostgreSQL database server**](#2). A database that stores chats and messages [🤖](https://github.com/jsbaan/ai-app-from-scratch/tree/main/db).
3. [**Database API**](#3). A FastAPI and Uvicorn Python server that queries the PostgreSQL database [🤖](https://github.com/jsbaan/ai-app-from-scratch/tree/main/db-api).
4. [**User interface**](#4). A FastAPI and Uvicorn Python server that serves HTML and support session-based authentication [🤖](https://github.com/jsbaan/ai-app-from-scratch/tree/main/chat-ui).
5. [**Private Docker network**](#5) For communication between microservices [🤖](https://github.com/jsbaan/ai-app-from-scratch/blob/main/compose.yaml#L2).
6. [**Nginx reverse proxy**](#6). A gateway between the outside world and network-isolated services [🤖](https://github.com/jsbaan/ai-app-from-scratch/tree/main/nginx).
7. [**Docker Compose**](#7). A container orchestration tool to easily run manage our services together [🤖](https://github.com/jsbaan/ai-app-from-scratch/blob/main/compose.yaml).


# 1. Language model API <a name="1"></a>

Setting up the actual language model is pretty easy, nicely demonstrating that ML engineering is usually more about engineering than ML. Since I want our app to run on a laptop, model inference should be fast and CPU-based with low memory. 

I looked at several inference engines, like [Fastchat with vLLM](https://github.com/lm-sys/FastChat/blob/main/docs/vllm_integration.md) or [Huggingface TGI](https://huggingface.co/docs/text-generation-inference/en/index), but went with [llama.cpp](https://github.com/ggerganov/llama.cpp/tree/master) because it’s popular, fast, lightweight and supports CPU-based inference. Llama.cpp is written in C/C++ and [conveniently provides a Docker image](https://github.com/ggerganov/llama.cpp/blob/master/examples/server/README.md) with its inference engine and a simple web server that implements the popular [OpenAI API specification](https://github.com/openai/openai-openapi?tab=readme-ov-file). It comes with a basic UI for experimenting, but we’ll build our own UI shortly. 

As for the actual language model, I chose the quantized [Qwen2.5-0.5B-Instruct](https://huggingface.co/Qwen/Qwen2.5-0.5B-Instruct-GGUF) model from Alibaba Cloud, whose responses are surprisingly coherent given how small it is.

## 1.1 Running the language model API

The beauty of containerized applications is that, given a Docker image, we can have it running in seconds without installing any packages. The `docker run` command below pulls the llama.cpp server image, mounts the model file that we downloaded earlier to the container’s filesystem, and runs a container with the llama.cpp server listening for HTTP requests at port 80. It uses flash attention and has max generation length of 512 tokens.

```bash
docker run
	--name lm-api \
	--volume $PROJECT_PATH/lm-api/gguf_models:/models \
	--publish 8000:80 \ # add this to make the API accessible on localhost
	ghcr.io/ggerganov/llama.cpp:server 
		-m /models/qwen2-0_5b-instruct-q5_k_m.gguf --port 80 --host 0.0.0.0 --predict 512 --flash-attn
```

Ultimately we will use Docker Compose to run this container together with the others [🤖](https://github.com/jsbaan/ai-app-from-scratch/blob/main/compose.yaml#L52).

## 1.2 Accessing the container

Since Docker containers are completely isolated from everything else on their host machine, i.e., our computer, we can’t reach our language model API yet.

However, we can break through a bit of networking isolation by publishing the container’s port 80 to our host machine’s port 8000 with `--publish 8000:80` in the docker run command. This makes the llama.cpp server available at http://localhost:8000. 

The hostname localhost resolves to the loopback IP address 127.0.0.1 and is part of the loopback network interface that allows a computer to communicate with itself. When we visit http://localhost:8000, our browser sends an HTTP GET request to our own computer on port 8000, which gets forwarded to the llama.cpp container listening at port 80. 

## 1.3 Testing the language model API

Let’s test the language model server by sending a POST request with a short chat history.

```bash
curl -X POST http://localhost:8000/v1/chat/completions \
-H "Content-Type: application/json" \
-d '{
	"messages": [
    {"role": "system", "content": "You are a helpful assistant."},
    {"role": "assistant", "content": "Hello, how can I assist you today?"},
    {"role": "user", "content": "Hi, what is an API?"}
	],
	"max_tokens": 10
	}'
```

The response is JSON and the generated text is under `choices.message.content`: “An API (Application Programming Interface) is a specification…”. 

Perfect! Ultimately, our UI service will be the one to send requests to the language model API, and define the system prompt and opening message [🤖](https://github.com/jsbaan/ai-app-from-scratch/blob/main/chat-ui/app/main.py#L216).

# 2. PostgreSQL database server <a name="2"></a>

Next, let’s look into storing chats and messages. [PostgreSQL](https://www.postgresql.org/) is a powerful, open-source relational database and running a PostgreSQL server locally is just another another `docker run` command using its official image. We’ll pass some extra environment variables to configure the database name, username, and password.

```bash
docker run --name db --publish 5432:5432 --env POSTGRES_USER=myuser --env POSTGRES_PASSWORD=mypassword postgres
```

After publishing port 5432, the database server is available on localhost:5432. PostgreSQL uses its own protocol for communication and doesn’t understand HTTP requests. We can use a database client like [psql](https://www.postgresql.org/docs/current/app-psql.html) to test the connection.

```bash
pg_isready -U joris -h localhost -d postgres
> localhost:5432 - accepting connections
```

When we deploy our application in [part 2](https://jorisbaan.nl/2025/01/14/ai-chat-app-from-scratch-part-2.html), we will use a database managed by a cloud provider to make our lives easier and add more security, reliability and scalability. However, setting one up locally like this is useful for local development and, perhaps later on, integration tests.

# 3. Database API <a name="3"></a>

Databases often have a separate API server sitting in front to control access, enforce extra security, and provide a simple, standardized interface that abstracts away the database’s complexity. 

We will build this API from scratch with [FastAPI](https://fastapi.tiangolo.com/), a modern framework for building fast, production-ready Python APIs. We will run the API with [Uvicorn](https://www.uvicorn.org/), a high-performance Python web server that handles things like network communication and simultaneous requests.

## 3.1 Quick FastAPI example

Let’s quickly get a feeling for FastAPI and look at a minimal example app with a single GET endpoint `/hello`.

```python
from fastapi import FastAPI

# FastAPI app object that the Uvicorn web server will load and serve
my_app = FastAPI()

# Decorator telling FastAPI that function below handles GET requests to /hello
@my_app.get("/hello") 
def read_hello():
    # Define this endpoint's response
    return {"Hello": "World"}
```

We can serve our app at http://localhost:8080 by running the Uvicorn server.

```bash
uvicorn main.py:my_app --host 0.0.0.0 --port 8080
```

If we now send a GET request to our endpoint by visiting http://localhost:8080/hello in our browser, we receive the JSON response `{"Hello": "World"}` !

## 3.2 Connecting to the database 

On to the actual database API. We define four endpoints in [main.py 🤖](https://github.com/jsbaan/ai-app-from-scratch/blob/main/db-api/app/main.py) for creating or fetching chats and messages. You get a nice visual summary of these in the auto-generated docs, see below. The UI will call these endpoints to process user data.

|                                                                                                 ![](/img/posts/ai-app-from-scratch-images/db-api-endpoints.png){: width="700" }                                                                                                  |
|:-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------:|
| A cool feature of FastAPI is that it automatically generates interactive documentation according to the [OpenAPI specification](https://www.openapis.org/) with [Swagger](https://swagger.io/). If the Uvicorn server is running we can find it at http://hostname:port/docs. 
 |



The first thing we need to do is to connect the database API to the database server. We use [SQLAlchemy](https://docs.sqlalchemy.org/en/13/orm/tutorial.html), a popular Python SQL toolkit and Object-Relational Mapper (ORM) that abstracts away writing manual SQL queries.

We establish this connection in [database.py 🤖](https://github.com/jsbaan/ai-app-from-scratch/blob/main/db-api/app/database.py) by creating the SQLAlchemy engine with a connection URL that includes the database hostname, username and password (remember, we configured these by passing them as environment variables to the PostgreSQL server). We also create a session factory that creates a new database session for each request to the database API.

## 3.3 Interacting with the database

Now let’s design our database. We define two SQLAlchemy data models in [models.py 🤖](https://github.com/jsbaan/ai-app-from-scratch/blob/main/db-api/app/models.py) that will be mapped to actual database tables. The first is a [Message model 🤖](https://github.com/jsbaan/ai-app-from-scratch/blob/main/db-api/app/models.py#L43) with an id, content, speaker role, owner_id, and session_id (more on this later). The second is a [Chat model 🤖](https://github.com/jsbaan/ai-app-from-scratch/blob/main/db-api/app/models.py#L21), which I’ll show here to get a better feeling for SQLAlchemy models:

```python
class Chat(Base):
    __tablename__ = "chats"

    # Unique identifier for each chat that will be generated automatically. This column is the primary key.
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)

    # Username associated with the chat. Index is created for faster lookups by username.
    username = Column(String, index=True)

    # Session ID associated with the chat. Used to "scope" chats, i.e., users can only access chats from their session.
    session_id = Column(String, index=True)

    # The relationship function links the Chat model to the Message model.
    # The back_populates flag creates a bidirectional relationship.
    messages = relationship("Message", back_populates="owner")
```

Database tables are typically created using migration tools like Alembic, but we’ll simply ask SQLAlchemy to create them in [main.py 🤖](https://github.com/jsbaan/ai-app-from-scratch/blob/main/db-api/app/main.py#L19). 

Next, we define the CRUD (Create, Read, Update, Delete) methods in [crud.py 🤖](https://github.com/jsbaan/ai-app-from-scratch/blob/main/db-api/app/crud.py). These methods use a fresh database session from our factory to query the database and create new rows in our tables. The endpoints in main.py will import and use these CRUD methods [🤖](https://github.com/jsbaan/ai-app-from-scratch/blob/main/db-api/app/main.py#L56).

## 3.4 Endpoint request and response validation

FastAPI is heavily based on [Python’s type annotations](https://fastapi.tiangolo.com/python-types/) and the data validation library [Pydantic](https://docs.pydantic.dev/latest/). For each endpoint, we can define a request and response schema that defines the input/output format we expect. Each request to or response from an endpoint is automatically validated and converted to the right data type and included in our API’s automatically generated documentation. If something about a request or response is missing or wrong, an informative error is thrown.

We define the Pydantic schemas for the database-api in [schemas.py 🤖](https://github.com/jsbaan/ai-app-from-scratch/blob/main/db-api/app/schemas.py) and use them in the endpoint definitions in [main.py 🤖](https://github.com/jsbaan/ai-app-from-scratch/blob/main/db-api/app/main.py#L45), too. For example, this is the endpoint to create a new chat:

```python
@app.post("/chats", response_model=schemas.Chat)
async def create_chat(chat: schemas.ChatCreate, db: Session = Depends(get_db)):
    db_chat = crud.create_chat(db, chat)
    return db_chat
```

We can see that it expects a ChatCreate request body and Chat response body. FastAPI verifies and converts the request and response bodies according to these schemas:

```python
class ChatCreate(BaseModel):
    username: str
    messages: List[MessageCreate] = []
    session_id: str

class Chat(ChatCreate):
    id: UUID
    messages: List[Message] = []
```

Note: our SQLAlchemy models for the database should not be confused with these Pydantic schemas for endpoint input/output validation.

## 3.5 Running the database API

We can serve the database API using Uvicorn, making it available at http://localhost:8001.

```bash
cd $PROJECT_PATH/db-api
uvicorn app.main.py:app --host 0.0.0.0 --port 8001
```

To run the Uvicorn server in its own Docker container, we create a [Dockerfile 🤖](https://github.com/jsbaan/ai-app-from-scratch/blob/main/db-api/Dockerfile) that specifies how to incrementally build the Docker image. We can then build the image and run the container, again making the database API available at http://localhost:8001 after publishing the container’s port 80 to host port 8001. We pass the database credentials and hostname as environment variables.

```bash
docker build --tag db-api-image $PROJECT_PATH/db-api
docker run --name db-api --publish 8001:80 --env POSTGRES_USERNAME=<username> --env POSTGRES_PASSWORD=<password> --env POSTGRES_HOST=<hostname> db-api-image
```

# 4. User interface <a name="4"></a>

With the backend in place, let’s build the frontend. A web interface typically consists of HTML for structure, CSS for styling and Javascript for interactivity. Frameworks like React, Vue, and Angular use higher-level abstractions like JSX that can ultimately be transformed into HTML, CSS, and JS files to be bundled and served by a web server like Nginx.

Since I want to focus on the backend, I hacked together a simple UI with FastAPI. Instead of JSON responses, its endpoints now return HTML based on template files that are rendered by [Jinja](https://jinja.palletsprojects.com/en/stable/), a templating engine that replaces variables in the template with real data like chat messages.

To handle user input and interact with the backend (e.g., retrieve chat history from the database API or generate a reply via the language model API), I’ve avoided JavaScript altogether by using [HTML forms 🤖](https://github.com/jsbaan/ai-app-from-scratch/blob/main/chat-ui/app/templates/home.html#L15) that trigger internal POST endpoints. These endpoints then simply use Python’s [httpx](https://www.python-httpx.org/) library to make HTTP requests [🤖](https://github.com/jsbaan/ai-app-from-scratch/blob/main/chat-ui/app/main.py#L107).

Endpoints are defined in [main.py 🤖](https://github.com/jsbaan/ai-app-from-scratch/blob/main/chat-ui/app/main.py), HTML templates are in the [app/templates directory 🤖](https://github.com/jsbaan/ai-app-from-scratch/tree/main/chat-ui/app/templates), and the static CSS file for styling the pages is in the [app/static directory 🤖](https://github.com/jsbaan/ai-app-from-scratch/tree/main/chat-ui/app/static). FastAPI serves the CSS file at `/static/style.css` so the browser can find it.

| ![](/img/posts/ai-app-from-scratch-images/ui-endpoints.png){: width="700" } |
|:---------------------------------------------------------------------------:|
|            Screenshot of the UI's interactive documentation.            
 |


## 4.1 Homepage

The homepage allows users to enter their name to start or return to a chat [🤖](https://github.com/jsbaan/ai-app-from-scratch/blob/main/chat-ui/app/main.py#L76). The submit button triggers a POST request to the internal `/chats` endpoint with username as form parameter, which calls the database API to create a new chat and then redirects to the [Chat Page 🤖](https://github.com/jsbaan/ai-app-from-scratch/blob/main/chat-ui/app/main.py#L89).

## 4.2 Chat Page

The chat page calls the database API to retrieve the chat history [🤖](https://github.com/jsbaan/ai-app-from-scratch/blob/main/chat-ui/app/main.py#L143). Users can then enter a message that triggers a POST request to the internal `/generate/{chat_id}`  endpoint with the message as form parameter [🤖](https://github.com/jsbaan/ai-app-from-scratch/blob/main/chat-ui/app/main.py#L184). 

The generate endpoint calls the database API to add the user’s message to the chat history, and then the language model API with the full chat history to generate a reply [🤖](https://github.com/jsbaan/ai-app-from-scratch/blob/main/chat-ui/app/main.py#L216). After adding the reply to the chat history, the endpoint redirects to the chat page, that again retrieves and displays the latest chat history. We send POST request to the LM API using httpx, but we could use a more standardized LM API package like langchain to invoke its completion endpoint.

## 4.3 Authentication & user sessions

So far, all users can access all endpoints and all data. This means anyone can see your chat given your username or chat id. To remedy that, we will use session-based authentication and authorization.

We will store a first party & GDRP compliant signed session cookie in the user’s browser [🤖](https://github.com/jsbaan/ai-app-from-scratch/blob/main/chat-ui/app/main.py#L61). This is just an encrypted dict-like object in the request/response header. The user’s browser will send that session cookie with each request to our hostname, so that we can identify and verify a user user and show them their own chats only.

As an extra layer of security, we “scope” the database API such that each chat row and each message row in the database contains a session id. For each request to the database API, we include the current user’s session id in the request header and query the database with both the chat id (or username) AND that session id. This way, the database can only ever return chats for the current user with its unique session id [🤖](https://github.com/jsbaan/ai-app-from-scratch/blob/main/db-api/app/crud.py#L65).

## 4.4 Running the UI

To run the UI in a Docker container, we follow the same recipe as the database API, adding the hostnames of the database API and language model API as environment variables.

```bash
docker build --tag chat-ui-image $PROJECT_PATH/chat-ui
docker run --name chat-ui --publish 8002:80 --env LM_API_URL=<hostname1> --env DB_API_URL=<hostname2> chat-ui-image
```

How do we know the hostnames of the two APIs? We will look networking and communication next.

# 5. Private Docker network <a name="5"></a>

Let’s zoom out and take a look at our architecture again. By now, we have four containers: the UI, DB API, LM API, and PostgreSQL database. What’s missing is the network, reverse proxy and container orchestration.

|                                                  ![](/img/posts/ai-app-from-scratch-images/local_architecture.png){: width="700" }                                                  |
|:-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------:|
| Architecture diagram. 
 |


Until now, we used our computer’s localhost loopback network to send requests to an individual container. This was possible because we published their ports to our localhost. However, for containers to communicate with each other, they must be connected to the same network and know each others hostname/IP address and port.

We will create a [user-defined bridge Docker network](https://docs.docker.com/network/drivers/bridge/#differences-between-user-defined-bridges-and-the-default-bridge) that provides automatic DNS resolution. This means that container names are resolved to their dynamic container’s IP address. The network also provides isolation, and therefore security: you have to be on the same network to be able to reach our containers.

```yaml
docker network create --driver bridge chat-net
```

We connect all containers to it by adding `--network chat-net` to their docker run command. Now, the database API can reach the database at db:5432 and the UI can reach the database API at [http://db-api](http://db-api:80) and the language model API at http://lm-api. Port 80 is default for HTTP requests so we can omit it. 

# 6. Nginx reverse proxy <a name="6"></a>

Now, how do we - the user - reach our network-isolated containers? During development we published the UI container port to our localhost, but in a realistic scenario you typically use a reverse proxy. This is another web server that acts like a gateway, forwarding HTTP requests to containers in their private network, enforcing security and isolation. 

[Nginx](https://nginx.org/en/) is a web server often used as reverse proxy. We can easily run it using its official [Docker image](https://hub.docker.com/_/nginx). We also mount a [configuration file 🤖](https://github.com/jsbaan/ai-app-from-scratch/blob/main/nginx/nginx.conf) in which we specify how Nginx should route incoming requests. As an example, the simplest possible configuration forwards all requests (location / ) from Nginx container’s port 80 to the UI container at http://chat-ui.

```yaml
http { server { listen 80; location / { proxy_pass http://chat-ui } } }
```

Since the Nginx container is in same private network, we can’t reach it either. However, we can publish its port so it becomes the only access point of our entire app [🤖](https://github.com/jsbaan/ai-app-from-scratch/blob/main/compose.yaml#L64). A request to http://localhost now goes to the Nginx container, who forwards it to the UI and the UI’s response back to us. 

```bash
docker run --network chat-net --publish 80:80 --volume $PROJECT_PATH/nginx.conf:/etc/nginx/nginx.conf nginx
```

In [part 2](https://jorisbaan.nl/2025/01/14/ai-chat-app-from-scratch-part-2.html) we will see that these gateway servers can also distribute incoming requests over copies of the same containers (load balancing) for scalability; enable secure HTTPS traffic; and do advanced routing and caching. We will use an Azure-managed reverse proxy rather this Nginx container, but I think it’s very useful to understand how they work and how to set one up yourself. It can also be significantly cheaper compared to a managed reverse proxy.

# 7. Docker Compose <a name="7"></a>

Let’s put everything together. Throughout this post we manually pulled or built each image and ran its container. However, in the codebase I’m actually using [Docker Compose](https://docs.docker.com/compose/): a tool designed to define, run and stop multi-container applications on a single host like our computer. 

To use Docker Compose, we simply specify a [compose.yml file 🤖](https://github.com/jsbaan/ai-app-from-scratch/blob/main/compose.yaml) with build and run instructions for each service. A cool feature is that it automatically creates a user-defined bridge network to connect our services. Docker DNS will resolve the service names to container IP addresses.

Inside the project directory we can start all services with a single command:

```
docker compose up --build
```

# Final thoughts

That wraps it up! We built an AI-powered chat web application that runs on our local computer, learning about microservices, REST APIs, FastAPI, Docker (Compose), reverse proxies, PostgreSQL databases, SQLAlchemy, and llama.cpp. We’ve built it with a cloud-native architecture in mind so we can deploy our app without changing a single line of code. 

We will discuss deployment in [part 2](https://jorisbaan.nl/2025/01/14/ai-chat-app-from-scratch-part-2.html) and cover Kubernetes, the industry-standard container orchestration tool for large-scale applications across multiple hosts; Azure Container Apps, a serverless platform that abstracts away some of Kubernetes’ complexities; and concepts like load balancing, horizontal scaling, HTTPS, etc.

# Roadmap

There is a lot we could do to improve this app. Here are some things I would work on given more time.

**Language model.** We now use a very general instruction-tuned language model as virtual assistant. I originally started this project to have a “virtual representation of me” on my website for visitors to discuss my research with, based on my scientific publications. For such a use case, an important direction is to improve and tweak the language model output. Perhaps that’ll become a part 3 of this series in the future.

**Frontend.** Instead of a quick FastAPI UI, I’d build a proper frontend using something like React, Angular or Vue to allow things like steaming LM responses and dynamic views rather than reloading the page every time. A more lightweight alternative that I’d like to experiment with is htmx, a library that provides modern browser features directly from HTML rather than javascript. It would be pretty straightforward to implement LM response streaming, for example.

**Reliability.** To make the system more mature, I’d add unit and integration tests and a better database setup like Alembic allowing for migrations.

# Acknowledgements

Thanks to Dennis Ulmer, Bryan Eikema and David Stap for initial feedback and proofreading.

## AI usage

I used Pycharm’s CoPilot plugin for code completion, and ChatGPT for a first version of the HTML and CSS template files. Towards the end, I started experimenting more with debugging and sparring too, which proved surprisingly useful. For example, I used it to learn about Nginx configurations and session cookies in FastAPI. I did not use AI to write this post, though I did use ChatGPT to paraphrase a few bad-running sentences.

Here are some additional resources that I found useful during this project.

- [Django vs Flask vs FastAPI YouTube video by Patrick Loeber](https://www.youtube.com/watch?v=3vfum74ggHE).
- The [FastAPI tutorial](https://fastapi.tiangolo.com/tutorial/) was by far most helpful.
- [Docker documentation](https://docs.docker.com/), especially the [networking overview](https://docs.docker.com/network/), [bridge network intro](https://docs.docker.com/network/drivers/bridge/), [docker-compose quickstart](https://docs.docker.com/compose/gettingstarted/) and [networks in docker-compose](https://docs.docker.com/compose/networking/).
- [SQLAlchemy docs and their Object-Relational Mapper (ORM) tutorial](https://docs.sqlalchemy.org/en/13/orm/tutorial.html).
- [PostgreSQL Cheat Sheet](https://www.postgresqltutorial.com/postgresql-cheat-sheet/).