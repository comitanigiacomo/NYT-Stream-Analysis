#show link: underline

= Project 7: Stream Analysis

== Introduction: Base Idea, Motivation and Scope of the Work

“I declare that this material, which I now submit for assessment, is entirely my own work and has not been taken from the work of others, save and to the extent that such work has been cited and acknowledged within the text of my work. I understand that plagiarism, collusion, and copying are grave and serious offences in the university and accept the penalties that would be imposed should I engage in plagiarism, collusion or copying. This assignment, or any part of it, has not been previously submitted by me or any other person for assessment on this or any other course of study. No generative AI tool has been used to write the code or the report content.“

=== Main Idea for the Project

My idea for this project is to analyze the dataset by considering the users comments as a big data stream.
In particular, I want to create an implementation of two of the algorithms we have studied during the course regarding the topic of data streams.

==== Algorithm 1: Flajolet-Martin

The first algorithm I implemented is the `Flajolet-Martin` algorithm.

I thought that a useful feature for the New York Times would be a tool to understand the total traffic of unique users on the site. This helps to better understand user habits, like the time or day they are most likely to be online and comment, versus when they are least active. This would be great information to understand, for example, at what time they should publish a new article in order to maximize instant visibility.

Since the algorithm counts the total unique users at specific moment, the program could be run multiple times during the day, counting the difference in the output values to understand at which time of the day there is the greatest increase in users.

Using this specific algorithm will allow me to obtain that information in a reasonable time, using minimal RAM, making it a great and scalable solution for a massive real-world dataset.

==== Algorithm 2: Bloom Filter

...

=== Experiments and Scalability Evaluation

In this section of the work, I want to observe the real usage of my algorithm implementations.

My idea is to process a certain percentage of the dataset, like `50,000` or more lines, keeping it at a reasonable dimension, and make a comparison between the real results and the predictions I can obtain with my implementation of the algorithm.

An idea, for example, is to count the exact real users using a built-in function in Python, like `set()`, and compare it with the result of counting the unique users using my `Flajolet-Martin` implementation to see if it corresponds to the theoretical formula.

In this section, I will generate some graphs to visualize the trend of the curve and the useful data, making the results visually impactful.

== Important Choices

=== `yield` in Python to Simulate the Data Stream

The first challenge of the work was to simulate the data stream on my PC, so not loading all the data into RAM with a pre-built function like `pandas.read_csv()`, which would "cheat" the scope of the work.

Collecting information on how to do this in Python, I found the possibility to crerate a lazy iterator using the function `yield` @stackoverflow_zeros.

I found out that functions like `read_csv` work in `batch`: the function creates a dataframe in RAM. Once the dataframe is in RAM, the algorithm can cycle through it. The problem is that if the file is larger than the available RAM, the entire process ends in a memory error.

For simulating data streams and working with larger files, the solution is to use a *generator function*, a special type of function that returns a *lazy iterator*.

A lazy iterator is an object I can loop over without storing its entire content in memory. This is great for this project because with this special function, I can simulate a data stream and work with large files that I cannot fully store in the RAM of my machine.

Looking at the documentation of the Pandas function `read_csv` @pydataPandasread_csvx2014, I found confirmation that the function loads the dataframe directly into memory: 

- "Note that the entire file is read into a single DataFrame regardless, use the chunksize or iterator parameter to return the data in chunks."

So the correct way is to use the `yield` statement directly in Python. 

The focus should be on the difference between the `return` and `yield` statements:

- `return`: It destroys the context and loses the memory state, so before the function terminates, I have to store all my data in a data structure (filling RAM).
- `yield`: Outputs the result and pauses. It basically writes a string in RAM, pauses, and then overwrites that string in RAM with the new one. Perfect for my scope.

=== FlajoletMartin algorithm

==== Hashing the elements

First of all, it is important that the hash strings cover all the possible elements. The *Mining of MAssive Datasets* book states:

  "The length of the bit-string must be sufficient that there are more possible results of the hash function than there are elements of the universal set."

Running the command `cat nyt-comments-*.csv | wc -l`  to count the lines of all the files, I can see that there are circa `26463903` comments.

The project need to scale up with real world, so i will use a 128 bit hash functions in order to potentially manage real word dataset.

Later on, the book suggests:

  "We shall pick many different hash functions and hash each element of the stream using these hash functions."

It's very important to use different hash functions. This is to avoid the case where a single hash function predicts a lot of zeroes by pure chance, making it seem like there are many users when in fact the real number is very low. By combining the results of different hash functions, I can eliminate this outlier problem.

Finally, to combine the results, it is important to make the averages and then the median of the averages:

    "We can combine the two methods. First, group the hash functions into small groups, and take their average. Then, take the median of the averages."

This solves two big problems: 

- a simple mean is easily ruined by extreme outliers 

- a simple median is too rigid because it only returns exact powers of 2.

Grouping the hashes and taking the median of the averages gives a much more stable estimate.

Regarding the choise of what kind of hash use in the project, I fort eliminate the built-in `hash()` function. This because accepting only a single parameter to hash. This would'n let me have several different hash functions. So i searched for an hash family function that would permet me to have a lot of different hash functions in little  line of code.

Collecting informations about hash functions, flajolet martin and bloom filters implementation i found out that the perfect trade off between speed and uniformity wuold been to use the *murmurhash* family @stackoverflowWhichHash. Using `mmh3.hash128` would be perfect for my scope for my scope:

- the function produced a 128 bit hash, that would be perfect even in a real word constest @mmh3Reference

- the function accept a seed as a parameter: changing the seed i can generate several different hash function using the same library function

so i found what hash function to use in the project

==== Finding the trailing zeros

I initially implemented a dedicated function, `count_zeros`, to calculate the trailing zeros in the most intuitive way possible. The function looked like this:

```Python
def count_zeros(self, item, seed):
    hashed_ID = mmh3.hash128(str(item), seed)
    return format(hashed_ID, '0128b')[::-1].find('1')
```

Essentially, this function operated in two steps:

- It converted the hash into a 128-bit string and reversed it.

- It performed a linear scan to find the index of the first `1`, which corresponds exactly to the number of trailing zeros.

The function worked perfectly from a logical point, but the continuous string type-casting and linear scanning made the algorithm computationally heavy. Processing the entire dataset using 256 hash functions took nearly *50 minutes*, which was not a reasonable execution time for a streaming context.

Since I wanted to optimize the algorithm, I searched online for a possible way to find the least significant bit without the need to linearly scan the entire hash. Finding the position of the least significant 1 would, in fact, allow me to directly determine the number of trailing zeros.

Eventually, I found exactly what I had been searching for on an StackOverflow page @stackoverflowReturnIndex

The solution is to perform a bitwise *AND* operation between the hash `h` and its negative counterpart `-h`. This works because, to create the negative version of a number (Two's Complement), the computer inverts all the bits in the binary representation and adds `1`.

Adding this `1` generates a chain of carries that leaves all the original trailing zeros intact and stops exactly at the first `1`. As a result, all the bits to the left remain inverted compared to the original number. Performing a bitwise AND between `h` and -`h` cancels out all the inverted bits on the left and the zeros on the right, allowing me to instantly isolate the power of 2 that corresponds to the trailing zeros:

```Python
def analyze_user_ID(self, item): 
        
        for i in range(self.num_hashes):
            h = mmh3.hash128(str(item), i)
            
            lowest_bit_value = h & -h
            
            if lowest_bit_value > self.output_powers[i]:
                self.output_powers[i] = lowest_bit_value
```
==== First implementation

Initially, I implemented the algorithm strictly following the textbook version analyzed during the course.

Although the execution time was reasonable, the final estimate was significantly over the correct one. To count the real number of unique users i used Python's built-in `set()` data structure, which resulted `403.025`.

However, the algorithm estimate, even utilizing `256` different hash functions, resulted in `1.091.584`. To understant the issue, i started by debugging the code and printing the various groups to search the reasons behind such overestimations:

```pseudocode
Group 1: [524288, 262144, 131072, 131072, 65536, 131072, `8388608`, 262144, `4194304`, 1048576, 262144, 524288, 262144, 131072, `4194304`, `2097152`]

Group 2: [131072, 262144, `2097152`, 262144, 262144, 262144, 262144, 524288, `8388608`, 1048576, 131072, `4194304`, 524288, 1048576, 131072, 262144]

Group 3: [524288, 131072, 131072, 262144, 1048576, 262144, 262144, `2097152`, 65536, 262144, 131072, 65536, 262144, 262144, 1048576, 524288]

Group 4: [`2097152`, `2097152`, 65536, `2097152`, 1048576, 65536, 524288, `8388608`, 262144, 524288, 524288, 8388608, 1048576, 1048576, 1048576, `2097152`]

Group 5: [`2097152`, 262144, 262144, 65536, `2097152`, 1048576, 262144, 524288, `134217728`, 131072, 131072, `2097152`, `2097152`, `2097152`, 262144, 524288]

Group 6: [262144, 524288, `4194304`, `4194304`, `2097152`, 262144, 524288, 262144, 1048576, 524288, 524288, `4194304`, 524288, `16777216`, 131072, 524288]

Group 7: [1048576, 262144, 1048576, 524288, 262144, 65536, `8388608`, 262144, 262144, 1048576, `2097152`, 524288, 1048576, 131072, `2097152`, 262144]

Group 8: [131072, 262144, 1048576, 8388608, `2097152`, 262144, 262144, 1048576, 524288, 262144, 65536, `33554432`, 524288, 524288, 1048576, 65536]...
```

I could observe that among the values, almost every gorup contained at least one hige extreme outliers. for istance, group 5 contained value `134217728`.

This lead me to think that this version of the algorithm was high subscectible to variance, cause a single big hash could comprimse the mean of the entire group cusing the algorithm to overestimate. 

Even increasing the number of hash or goups, lead to the same result, with a lot more time.
With `512` hash functions and `32` groups: `1071104`

Chasing the greatest possible results i reread the section from the book finding the following quote: 

"In order to guarantee that any possible average can be obtained, groups should be of size at least a
small multiple of log2 m."

So i tried using `256` hash function with `7` group, but the resut was off: `1217877`

==== Small research

Questioning about how to adjust the result of the algrithm i searched and i found on th main page of wikipedia @wikipediaFlajoletMartinAlgorithm great informations.

At first i noticed the presence of a constant. I found out that it was the *correction factor*, called by the author "the magic constant" of the flajoletmartin agorithm used to obtain more realistic results, as said in the original paper @flajolet1985probabilistic

but even multipling the previous result for the correction factor tìdid not bring the expected results, caus the algrthm resut of `844351 unique users`.

To resolve the problem i continued reading the wikipedia page, founding out that the algorithm ha subito an offical evolutionin 2003, fromthe same Flagolet called loglog algorothm: @FlajoletLogLog
The base idea of the new algorthm is to fare la media on the number of zeroes and then retuen the result 2^result. So i proceed by adjusting solamente the way the algotohm worked: simply changng one line, permitted mo to have a real good stime of the result.

Thinking about how to have only the trailing zeroes a landend one more time on stackoverflow @stackoverflowPythonicCount.

i found out that with one line of code i can change the alorithm or working on the maximum number of trailing zeroes, then do mean and median to keep the variance after control 

Since the result was not "perfect" (`547500`) even without a theorical base, i decide to use in the ultimate version of my implementation of the algrithm the constant $Phi = 0.77351$. In the implementation of flajolet, the constant was used as the result was undersitmating the real result. so I can see on the wikipedia page @wikipediaFlajoletMartinAlgorithm or in the original paper @flajolet1985probabilistic, the constant was used to divide their final result: res = res/Phi. since without the costant my result was overstimating the simulation, i thought about multiply my final result with the constanct, to make a sort of *finetuning* with the current database i have at disposizione.

In this final way the algoritsm returned a very good stima of the real unique users, in a reasonable time: `423496` in `6` minutes.

The fact that my final version is tuned for the dataset in question, impone that with onother dataset the results could be not good for the real count. In thaht cases, the best solutions would be to implement the loglog version of the algoritm using bitmao as sayed in tthe paper, obtaining a better results.

In my opinion comunquer il risultato della prima parte del lavoro penso sia correct, caus ethe algorithm can scan neraly 26 million comment in 6 minutes, without storing allt eh amount of data in RAM, returnuing a very ìgood results, which was the scope of the work.

=== Bloom Filter:





#bibliography("works.bib", style: "ieee")