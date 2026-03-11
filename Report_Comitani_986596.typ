#show link: underline

= Project 7: Stream Analysis

== Introduction: Base Idea, Motivation and Scope of the Work

“I declare that this material, which I now submit for assessment, is entirely my own work and has not been taken from the work of others, save and to the extent that such work has been cited and acknowledged within the text of my work. I understand that plagiarism, collusion, and copying are grave and serious offences in the university and accept the penalties that would be imposed should I engage in plagiarism, collusion or copying. This assignment, or any part of it, has not been previously submitted by me or any other person for assessment on this or any other course of study. No generative AI tool has been used to write the code or the report content.“

=== Main Idea for the Project

My idea for this project is to analyze the dataset by considering the users comments as a big data stream.
In particular, I want to create an implementation of two of the algorithms we have studied during the course regarding the topic of data streams.

==== Algorithm 1: Flajolet-Martin

The first algorithm I implemented is the Flajolet-Martin algorithm.

I thought that a useful feature for the New York Times would be a tool to understand the total traffic of unique users on the site. This helps to better understand user habits, like the time or day they are most likely to be online and comment, versus when they are least active. This would be great information to understand, for example, at what time they should publish a new article in order to maximize instant visibility.

Since the algorithm counts the total unique users at specific moment, the program could be run multiple times during the day, counting the difference in the output values to understand at which time of the day there is the greatest increase in users.

Using this specific algorithm will allow me to obtain that information in a reasonable time, using minimal RAM, making it a great and scalable solution for a massive real-world dataset.

==== Algorithm 2: Bloom Filter

I thought that another cool feature for the New York Times would be a spam filter. In this sense, the scope of the functionality would be to block bots or users with propagandistic intentions. For this work, I will implement a Bloom filter that works upon specific text.

To avoid issues, the text will first be converted into lowercase with no punctuation.

Having this tool will allow the New York Times to maintain clean articles with no propaganda in the comments.

=== Experiments and Scalability Evaluation

In this section of the work, I want to observe the real usage of my algorithm implementations.

My idea is to process a certain percentage of the dataset, like 50,000 or more lines, keeping it at a reasonable dimension, and make a comparison between the real results and the predictions I can obtain with my implementation of the algorithm.

An idea, for example, is to count the exact real users using a built-in function in Python, like set(), and compare it with the result of counting the unique users using my Flajolet-Martin implementation to see if it corresponds to the theoretical formula.

In the same way, I can test my Bloom filter by passing a user I know should not pass, to see if the percentage of false positives falls within the theoretical range.

In this section, I will generate some graphs to visualize the trend of the curve and the useful data, making the results visually impactful.

== Important Choices

=== `yield` in Python to Simulate the Data Stream

The first challenge of the work was to simulate the data stream on my PC, so as not to load all the data into RAM with a pre-built function like `pandas.read_csv()`, which would "cheat" the scope of the work.

To collect information on how to do this in Python, I found the following page about creating a generator using yield:

#link("https://realpython.com/introduction-to-python-generators/")[
  generators and yield in Python
]

I found out that functions like `read_csv` work in batch: the function creates a dataframe in RAM. Once the dataframe is in RAM, the algorithm can cycle through it. The problem is that if the file is larger than the available RAM, the entire process ends in a memory error.

For simulating data streams and working with larger files, the solution is to use a generator function, a special type of function that returns a *lazy iterator*.

A lazy iterator is an object I can loop over without storing its entire content in memory. This is great for this project because with this special function, I can simulate a data stream and work with large files that I cannot fully store in the RAM of my machine.

Looking at the documentation of the Pandas function `read_csv` (https://pandas.pydata.org/docs/reference/api/pandas.read_csv.html), I found confirmation that the function loads the dataframe directly into memory: 

- "Note that the entire file is read into a single DataFrame regardless, use the chunksize or iterator parameter to return the data in chunks."

So the correct way is to use the `yield` statement directly in Python. 

The focus should be on the difference between the `return` and `yield` statements:

- `return`: It destroys the context and loses the memory state, so before the function terminates, I have to store all my data in a data structure (filling RAM).
- `yield`: Outputs the result and pauses. It basically writes a string in RAM, pauses, and then overwrites that string in RAM with the new one. Perfect for my scope.

=== Using `DictReader` to Store the Comments

Once I set up a rudimentary lazy generator, with the aim of understanding what I had to work with, I printed the very first lines of the first file:

```terminal
commentID,status,commentSequence,userID,userDisplayName,userLocation,userTitle,commentBody,createDate,updateDate,approveDate,recommendations,replyCount,editorsSelection,parentID,parentUserDisplayName,depth,commentType,trusted,recommendedFlag,permID,isAnonymous,articleID

104387472,approved,104387472,60215558,magicisnotreal,earth,,"Here is something I think is fraudulent that vets are subject to

 If you use your VA home loan option you have to pay higher interest rates regardless of your credit rating becuase supposedly it is more risky...
```

I noted that with the presence of numerous spaces and commas even in the same field, using a normal `.split()` function would have been a mess, both for storing the data and extracting it.

Using the `DictReader` function from the `csv` library instead is much more useful. It reads the first line of the document, and then, also with lazy evaluation, it uses the first line to map the information of each row to a dictionary.

Using this function, I can get a much better output:

```pseudocode
{'commentID': '104387472', 'status': 'approved', 'commentSequence': '104387472', 'userID': '60215558', 'userDisplayName': 'magicisnotreal', 'userLocation': 'earth'...}
```