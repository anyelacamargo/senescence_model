d <- read.table('fitness_all.txt', header=FALSE, sep ='\t')
boxplot(V6 ~ V1, data =d, notch = TRUE, las=2, ylim = c(5,10))
