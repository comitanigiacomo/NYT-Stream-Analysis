#import "@preview/ilm:2.0.0": *

#set text(lang: "en")
#set text(size: 10.5pt)

#show: ilm.with(
  title: [Project 7: Data Streaming Algorithms],
  authors: "Giacomo Comitani",
  date: datetime(year: 2026, month: 03, day: 20),
  abstract: [This report presents the implementation of two fundamental streaming algorithms, Flajolet-Martin and Bloom Filter. The algorithms were applied to the New York Times comments datasets from 2020. The Flajolet-Martin algorithm is used to calculate the number of unique users that have commented, using an approach that combines ideas from the original 1985 paper and the updated LogLog version of 2003 to obtain a correct result in a reasonable time. The Bloom Filter isolates the comments regarding science articles, with all the parameters chosen and justified by theoretical bases. The results of the work demonstrated that both the implementations returned accurate results, achieving a relative error of 5% for the Flajolet-Martin estimate and a False Positive Rate of 0.3% for the filter, in a reasonable time. Both implementations achieved $O(1)$ space complexity and linear time complexity, making them suitable for real-world data streams.],
  table-of-contents: none,
  bibliography: bibliography("works.bib"),
)

#set page(
  header: context [
    #set text(size: 10pt)
    Giacomo Comitani -- 85673A
    #line(length: 100%, stroke: rgb("#919191"))
  ],
  footer: context [
    #line(length: 100%, stroke: rgb("#919191"))
    #set text(size: 10pt)
    University of Milan -- Department of Computer Science
    #h(1fr)
    #counter(page).display()
  ],
)

= Project 7: Stream Analysis

== Initial Declarations

“I declare that this material, which I now submit for assessment, is entirely my own work and has not been taken from the work of others, save and to the extent that such work has been cited and acknowledged within the text of my work. I understand that plagiarism, collusion, and copying are grave and serious offences in the university and accept the penalties that would be imposed should I engage in plagiarism, collusion or copying. This assignment, or any part of it, has not been previously submitted by me or any other person for assessment on this or any other course of study. No generative AI tool has been used to write the code or the report content.“

_All the experimental results of the project refer to the version of the dataset downloaded on 20 March 2026._

=== Main Idea for the Project

My idea for the project was to first implement the *Flajolet-Martin* algorithm to count the number of unique users who commented on the New York Times in 2020. After that, I implemented a Bloom Filter which was used to filter and count the comments made on articles regarding Science.

==== Algorithm 1: Flajolet-Martin

The first algorithm I implemented is the *Flajolet-Martin* algorithm.

I thought that a useful feature for the New York Times would be a tool to understand the total traffic of unique users on the site. This helps to better understand user habits, like the time or day they are most likely to be online and comment, versus when they are least active. This would be a great information to understand, for example, at what time they should publish a new article in order to maximize visibility.

Since the algorithm counts the total unique users at specific moment, the program could be run multiple times during the day, counting the difference in the output values to understand at which time of the day there is the greatest increase in users.

==== Algorithm 2: Bloom Filter

After the implementation of the *Flajolet-Martin* algorithm, I focused on implementing the *Bloom Filter*. By grouping all the comments regarding articles of a specific section, I thought it would be a great feature for the New York Times website to create dedicated subsections. This way, if a user wants to see only specific information, he could land on a specific page with all the information only for that section.
To understand which section to build first, a programmer would need to see which sections receive the most comments. With the Bloom Filter, this information can be obtained in a fast and reasonable way.

#pagebreak()

=== Experiments and Scalability Evaluation

In this section of the project, I observed the real-world performance of my implementations.

The approach was to process the dataset and compare the exact result obtained with some built-in Python functions like `set()`, with the estimates obtained from my implementations of the algorithms. This allowed me to verify if the accuracy corresponds to the theoretical formula.

== Important Choices

=== `yield` in Python to Simulate the Data Stream

The first challenge of the work was to simulate the data stream on my PC. This meant I couldn't load all the data into RAM using a pre-built function like `pandas.read_csv()`, because that would "cheat" the scope of the work.

While researching how to do this in Python, I found the possibility to create a lazy iterator using the keyword `yield` @stackoverflow_zeros.

I found out that functions like `read_csv` work in `batch`: they create a dataframe in RAM first, then the algorithm can cycle through it. The problem is that if the file is larger than the available RAM, the entire process ends in a memory error.

To simulate data streams and work with larger files, the solution is to use a *generator function*, a special type of function that returns a lazy iterator.

A *lazy iterator* is an object that I can loop over without storing its entire content in memory. This is perfect for this project because it allows me to simulate a continuous stream and process large files that are too big for my machine's RAM.

Looking at the official Pandas documentation for `read_csv` @pydataPandasread_csvx2014, I found confirmation that the function loads everything directly into memory:

_"Note that the entire file is read into a single DataFrame regardless, use the chunksize or iterator parameter to return the data in chunks."_

So the best approach was to use the *yield* statement directly in Python. This is because the *return* statement terminates the function and destroys its context, meaning that it has to compute and store all the data before the function ends. Instead, the *yield* statement outputs the result and pauses, processing the data step by step without storing the entire dataset.

=== Flajolet-Martin algorithm

==== Hashing the elements

First of all, it is important that the hash values cover all the possible elements. The *Mining of Massive Datasets* textbook states:

_"The length of the bit-string must be sufficient that there are more possible results of the hash function than there are elements of the universal set."_

Running the command:

#align(center)[
  ```terminal
   cat nyt-comments-part*.csv | wc -l
  ```
]
to count the total number of lines, I can see that they are circa `13,231,956`.

The project needs to scale up with real-world scenarios, so I used a 128-bit hash functions in order to potentially manage massive datasets.

Later on, the book suggests:

_"We shall pick many different hash functions and hash each element of the stream using these hash functions"._

It's very important to use different hash functions, to avoid the case where a single hash function predicts a lot of zeros by chance, making it seem like there are many users when in fact the real number is very low. By combining the results of different hash functions, I eliminated the outlier problem.

Finally, to combine the results, I calculated the averages and then the median of those averages:

_"We can combine the two methods. First, group the hash functions into small groups, and take their average. Then, take the median of the averages."_

This solves two big problems:

- A simple mean is easily ruined by extreme outliers

- A simple median is too rigid because it only returns exact powers of 2.

Grouping the hashes and taking the median of the averages gives a much more stable estimate.

Regarding the choice of which hash function to use in the project, I first discarted the built-in Python `hash()` function. This because it only accepts a single parameter to hash, which wouldn't allow me to have several different hash functions. So I searched for a hash function family that would permit me to generate many different hashes in a few lines of code.

Collecting information about hash functions and the implementation of Flajolet-Martin and bloom filters, I found out that the perfect trade-off between speed and uniformity was the *MurmurHash* family @stackoverflowWhichHash. Using `mmh3.hash128` was perfect for my scope:

- The function produced a 128-bit hash, which is perfect even in a real-word context @mmh3Reference

- The function accepts a seed as a parameter: changing the seed, I could generate several different hash functions using the same library function.

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

The function worked perfectly from a logical point, but the continuous string casting and linear scanning made the algorithm slow. Processing the entire dataset using `256` hash functions took nearly *50 minutes*, which was not a reasonable execution time for a streaming context.

Since I wanted to optimize the algorithm, I searched online for a possible way to find the least significant bit without the need to linearly scan the entire hash.

Eventually, I found exactly what I had been searching for on a StackOverflow page @stackoverflowReturnIndex.

The solution was to perform a bitwise *AND* operation between the hash `h` and its negative counterpart `-h`. This works because, to create the negative version of a number, the computer inverts all the bits in the binary representation and adds `1`.

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

Although the execution time was reasonable, the final estimate was significantly over the correct one. To count the real number of unique users I used Python's built-in `set()` data structure, which resulted in `403,025`.

However, the algorithm's estimate, even utilizing `256` different hash functions, resulted in `1,091,584`. To understand the issue, I started by debugging the code and printing the various groups to find the reasons behind this overestimation:

#pagebreak()

```python
Group 1: [524288, 262144, 131072, 131072, 65536, 131072, `8388608`, 262144, `4194304`, 1048576, 262144, 524288, 262144, 131072, `4194304`, `2097152`]

Group 2: [131072, 262144, `2097152`, 262144, 262144, 262144, 262144, 524288, `8388608`, 1048576, 131072, `4194304`, 524288, 1048576, 131072, 262144]

Group 3: [524288, 131072, 131072, 262144, 1048576, 262144, 262144, `2097152`, 65536, 262144, 131072, 65536, 262144, 262144, 1048576, 524288]

Group 4: [`2097152`, `2097152`, 65536, `2097152`, 1048576, 65536, 524288, `8388608`, 262144, 524288, 524288, 8388608, 1048576, 1048576, 1048576, `2097152`]

Group 5: [`2097152`, 262144, 262144, 65536, `2097152`, 1048576, 262144, 524288, `134217728`, 131072, 131072, `2097152`, `2097152`, `2097152`, 262144, 524288]

Group 6: [262144, 524288, `4194304`, `4194304`, `2097152`, 262144, 524288, 262144, 1048576, 524288, 524288, `4194304`, 524288, `16777216`, 131072, 524288]

Group 7: [1048576, 262144, 1048576, 524288, 262144, 65536, `8388608`, 262144, 262144, 1048576, `2097152`, 524288, 1048576, 131072, `2097152`, 262144]

Group 8: [131072, 262144, 1048576, 8388608, `2097152`, 262144, 262144, 1048576, 524288, 262144, 65536, `33554432`, 524288, 524288, 1048576, 65536]...
```

I observed that almost every group contained at least one huge extreme outlier. For instance, group 5 contained value `134,217,728`.

This led me to think that this version of the algorithm was high susceptible to variance, because a single big hash could compromise the mean of the entire group, causing the algorithm to overestimate.

Even increasing the number of hash functions or groups led to the same result, just taking a lot more time. With `512` hash functions and `32` groups, the result was still `1,071,104`

Chasing a better result, I reread the section from the book and found the following quote:

_"In order to guarantee that any possible average can be obtained, groups should be of size at least a small multiple of log2 m."_

So i tried using `256` hash functions with `7` group, but the resut was still off: `1,217,877`

==== Small research

Wondering how to adjust the algorithm's result, I searched and found great information on the main wikipedia page for the Flajolet-Martin algorithm @wikipediaFlajoletMartinAlgorithm.

At first I noticed the presence of a constant. I found out that it was a *correction factor*, called by the author "the magic constant" $(phi = 0.77351)$ used to obtain more realistic results, as stated in the original paper @flajolet1985probabilistic.

However, even multiplying the previous result for the correction factor did not bring the expected result, because the algorithm result was still `844,351` unique users.

To resolve the problem, I continued reading the wikipedia page and found out that the algorithm underwent an official evolution in 2003 by the same author, called the *loglog* algorithm @FlajoletLogLog. The base idea of this new algorithm is to calculate the average of the maximum number of trailing zeroes directly, and then return $2^"average"$. So I proceeded by adjusting only the way my algorithm worked: simply changing one line of logic allowed me to get a really good estimate.

Thinking about how to efficiently extract only the trailing zeros, I landed one more time on StackOverflow @stackoverflowPythonicCount.

I found out that with one line of code I could update the algorithm to work directly on the maximum number of trailing zeroes, and then apply the mean and median grouping to keep the variance after control.

Since the result was still not "perfect" (`547,500`), even without a theorical base, I decided to use the constant $phi = 0.77351$ in the ultimate version of my implementation. In the original Flajolet-Martin implementation, the algorithm usually underestimates the real result. As I saw on the wikipedia page @wikipediaFlajoletMartinAlgorithm and in the original paper @flajolet1985probabilistic, the constant was used to divide the final result: $"res" = "res"/phi$. Since my implementation without the constant was overestimating, I decided to *multiply* my final result by the constant, to do a sort of *fine-tuning* specifically for the nyt dataset.

With this final implementation the algorithm returned a very good estimate of the real unique users in a reasonable time: `423,496` in `6` minutes (`9` on colab)

The fact that my final version is tuned for the dataset in question means that, with another dataset, the results might not be accurate. In that case, the best solutions would be to implement the loglog algorithm as described in the original paper, to obtain better results.

=== Bloom Filter:

Following the suggestion in the project description, I decided to build a bloom filter for comments regarding articles of a specific section.

My goal was to first scan the articles file to save the hashes of the `Science` articles, building the Bloom Filter. Then, I scanned the stream of million comments to identify only the comments made on science articles.

This approach was great for the scope of the project, because without the bloom filter, a standard search tree or hash table wouldn't fit in RAM.

In a real-world example this mechanism would be perfect for isolating a specific stream of comments to create a dedicated view on a website, or in any other context where a user only wants to see science-related discussions.

==== Creating the trusted list S

First of all, I needed to create my trusted list $S$, which is basically the collection of all the article IDs regarding science.

To understand the structure of the CSV file I printed out the first line:

```terminal
head -n 1 nyt-articles-2020.csv
newsdesk,section,subsection,material,headline,abstract,keywords,word_count,pub_date,n_comments,uniqueID
```

So I needed to extract the `uniqueID` field whenever the `section` field was equal to `Science`.

The first implementation that came to my mind to create the initial trusted list was to use the built-in Python `set()` data structure:

```python
import csv

def create_trusted_list(repo):
    s = set()

    with open(repo + "nyt-articles-2020.csv", mode='r', encoding='utf-8') as file:
        reader = csv.reader(file)
        headers = next(reader)
        article_id = headers.index("uniqueID")
        article_section = headers.index("section")
        for row in reader:
            if row[article_section] == "Science":
                s.add(row[article_id])
    return s
```

However in this way, if the initial file was too big, I would load too much data into the RAM all at once. The solution, once again, was to use the *yield* keyword to create a generator:

```python
def create_trusted_list(repo):
    with open(repo + "nyt-articles-2020.csv", mode='r', encoding='utf-8') as file:
        reader = csv.reader(file)
        headers = next(reader)

        article_id = headers.index("uniqueID")
        article_section = headers.index("section")

        for row in reader:
            if row[article_section] == "Science":
                yield row[article_id]
```

==== Construction (Pre-processing S):

In this phase I needed to initialize an array of `m` bits to `0`, choose `k` independent hash functions and, for every key in $S$, hash it with all `k` functions. Finally, I had to set the bits at those resulting indices to `1`.

To understand what value assign to $m$, I initially checked the length of my trusted list $S$: `354` unique articles ($n = 354$)

In example `4.4.3` of the textbook, the author assigns `8` bits of memory for each element inserted in the filter. With the goal of scaling up my algorithm for real-world scenarios, I assigned `10` bits per element. Since there are `354` elements in the trusted list, I calculated $m = 354 * 10 = 3540$

The textbook later suggests:

_"We might choose $k$, the number of hash functions, to be $m/n$ or less"_

Since in this case $n = 354$ and $m = 3540$, the ratio $m/n = 10$

Starting from `10`, I tried  some different values for `k` until I found  $k= 7$ provided the best result.

== Conclusions

=== Flajolet-Martin implementation

The algorithm returned a very good estimate of the real unique users in a reasonable time: `423,496` in `6` minutes. Considering that the real number of users, calculated by finding the length of the built-in `set()` data structure was `403,025`, this means that the implementation had an error of:

$ 423,496 - 403,025 = 20,471 $

This translates to a relative error of $(20,471)/(403,025) = 5%$ in `6` minutes, while scanning `13,231,956` lines and using little RAM due to the techniques described above. In my opinion, this makes the implementation suitable for massive datasets in real-world scenarios.

=== Flajolet Scalability Analysis

The space complexity is $O(1)$. This is because, regardless of the size of the dataset, due to the use of `yield`, the step-by-step results are continuously overwritten. As a result, only one hash is present in the RAM at any given time.

During the experimental phase, by changing the number of hashes or the number of groups, I could observe that the time complexity was linear: $O(N times "num_hashes")$ where $N$ is the size of the dataset. This happens because the execution time increases as the number of hashes increases, due to the `for` loop inside the `analyze_user_ID` function.

=== Bloom Filter implementation

Regarding the implementation of the bloom filter, I made an analysis based on the theory I learned in class.

The algorithm returned a value of `39,888` comments about science out of `4,986,461` total comments. To verify the real number, I once again utilized the built-in  Python `set()`, to count the exact number of comments and compared it with the result produced by the filter. This way, I found that the real number of comments regarding Science was `23,698`.

To verify if this was a great result, I can use the mathematical theory that is behind the bloom filter.

The probability that a bit of the bit array is `1` is $1 - e^(-k*(n/m))$. considering that:

- $n = 354$ (science articles)
- $m = 3540$  (size of the array of zeros)
- $k = 7$ (number of the hash functions)

$ 1 - e^(-k*(n/m)) = 1 - e^(-7 * 0.1) = 1 - 0.496 = 0.504 $

Since this is the probability of finding a random bit set to `1`, to understand how many bits will be turned on after the initial hashing phase, I can calculate the expected value $E$ as:

$ E = 3540 * 0.504 = 1784 $


Since I expected to have `1784` bits set to `1`, this means that my filter will be full by the  $1784/3540 = 50.4%$

This is not a casual result, since the filter works well when it is half full, and I observed that $k=7$ gave me the best possible result.

Finally, I can calculate the False Positive rate (FPR):

$ "FPR" = (1 - e^(-k * n/m))^k = 0.504^7 = 0.8% $

So theoretically my bloom filter should have an error rate of about 0.8 %.

Considering that:

- The filter analyzed `4,986,461` comments
- The real number of comments about articles regarding science were: `23,698`
- The comments to discard = $4,986,461 - 23,698 = 4,962,763$
- The output of the bloom filter (comments probably about science) = `39,888`

The False Positives (FP) actually obtained by the filter were: 

$ 39,888 - 23,698 = 16,190 $

The True Negatives (TN) correctly discarted by the filter were:

$ 4,962,763 - 16,190 = 4,946,573 $

By calculating the real FPR using the explicit formula $"FPR" = ("FP")/("FP" + "TN")$:

$ "FPR"_("real") = (16,190) / (16,190 + 4,946,573) = 0.003 $

So the filter obtained an error of 0.3%, a great result.

=== Bloom Filter Scalability Analysis

The space complexity is completely independent of the stream size $N$, because in the implementation I set a fixed amount of RAM $m = 3540$ bits (only the array of bits will be loaded into RAM).

The time complexity can be calculated considering the loop to create the filter, and then the time the filter is used on the data stream, resulting in $O(N times k)$ where $k$ is the number of hash functions.

So basically, the implementation of the algorithm can scale up to millions of comments in a real-world context.