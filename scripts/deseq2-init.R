library("dplyr")
library("DESeq2")

counts = snakemake@input[['counts']]

metadata <- snakemake@params[['samples']]

sampleID <- snakemake@params[['sample_id']]

Type <- snakemake@params[['linear_model']]

contrast <- snakemake@params[['contrast']]

baseline <- contrast[[2]]

target <- contrast[[1]]

output = snakemake@output[['rds']]

rld_out = snakemake@output[['rld_out']]

parallel <- FALSE
if (snakemake@threads > 1) {
    library("BiocParallel")
    # setup parallelization
    register(MulticoreParam(snakemake@threads))
    parallel <- TRUE
}

# Read in metadata table and order according to sampleID
md <- read.delim(file=metadata, sep = "\t", stringsAsFactors = FALSE)
md <- md[order(md[sampleID]),]

# Read in counts table
subdata <- read.table(counts, header=TRUE, row.names=1, sep="\t", check.names=FALSE)
colnames(subdata) = sub("results.ciri_out.", "", colnames(subdata))

# Set all missing count values to zero
subdata[is.na(subdata)] <- 0

# order the same as the metadata file
subdata <- subdata[,order(colnames(subdata))]
# Extract only the Types that we want in further analysis & only the PP_ID and Status informative columns
md <- md[md[[Type]]==baseline | md[[Type]]==target,]
md <- md[md[[sampleID]] %in% colnames(subdata),]

# Keep only the PP_IDs of the types we have chosen in the metadata table above
rownames(md) <- md[[sampleID]]
md[[sampleID]] <- NULL

keep <- colnames(subdata)[colnames(subdata) %in% rownames(md)]
subdata <- subdata[, keep]
dim(subdata)

# Check
stopifnot(rownames(md)==colnames(subdata))

# Obtain the number of genes that meet padj<0.01 for reference line in histogram
dds <- DESeqDataSetFromMatrix(countData=subdata,
                              colData=md,
                              design= as.formula(paste('~',Type)))

dds <- estimateSizeFactors(dds)

# Remove uninformative columns
dds <- dds[ rowSums(counts(dds)) >= 1, ]

# Normalization and pre-processing
dds <- DESeq(dds, parallel=parallel)

saveRDS(dds, file=output)

# colData and countData must have the same sample order, but this is ensured
# by the way we create the count matrix
dds <- dds[ rowSums(counts(dds)) > 1, ]
# normalization and preprocessing
dds <- DESeq(dds, parallel=parallel)
saveRDS(dds, file=output)

# obtain normalized counts
rld <- rlog(dds, blind=FALSE)
saveRDS(rld, file=rld_out)

