# Jr-server
>Jason Registry Server

Prototype for Jason Registry backend for [Jr client website](https://github.com/Jasonette/Jr)

## Features

1. Provides an endpoint to register a new Jason extension by submitting a github URL.
2. Provides an endpoint that returns all registered Jason extensions.
3. Provides an endpoint for full text search the registry.

## How it works

1. `POST` a github url that follows the guideline (For now, need to have a `jr.json` file that contain information about the extension) to `/jrs.json` endpoint.
2. The registry then crawls the `jr.json` content to validate.
3. If valid
  A. If the extension is not yet reistered, the registry server forks the repo into `JasonExtension-iOS/[USER_NAME]_[REPO_NAME]` or `JasonExtension-Android/[USER_NAME]_[REPO_NAME]`.
  B. If the extension is already registered, the server `git pull` from upstream repo (in this case the original extension repo) and re-push to the `JasonExtension*` organization repos.
4. Lastly, the server stores the relevant information into the database, while incrementing the version.

## Routes

- `GET` https://jasonx.herokuapp.com/jrs.json
	- **Behavior:** Returns all registered extensions
- `GET` https://jasonx.herokuapp.com/jrs/1.json
	- **Behavior:** Returns an extension by ID
- `GET` https://jasonx.herokuapp.com/search/demo+two.json
	- **Behavior:** Returns a full text search result
- `POST` https://jasonx.herokuapp.com/jrs.json
	- **params**: `url` => Github url (Example: https://github.com/gliechtenstein/JasonDemoAction)
	- **Behavior:**
		- If the github repo is already registered, it increments the version number by 1.
		- If the github repo is not registered, it creates an entry with version 1.

## Challenges
Currently the challenge is the part `3B` from the [#how_it_works](How it works) section above. So far it successfully does all `git clone`, `git pull`, `git add`, and `git commit`, but unable to `git push`, beause of credntial issues.

Need to figure out whether:

1. Should we use github api to do this?
2. Is there a way to use credentials in the gems we're using? Or maybe another library?
3. Should we use a completely different solution? Maybe set up a jenkins or other CI tasks that connect seamlessly with Github and trigger that instead of running everything in one server?
