# command line arguments, specifying input/output file names and phenotype subset
arg = commandArgs(T);
ref.prefix = arg[1];
loc.file = arg[2];
info.file = arg[3];
sample.overlap.file = arg[4];
phenos = unlist(strsplit(arg[5]," "));
locus.number = arg[7];
target = arg[8];
out.fname = arg[6];
output_path=arg[9];
output_file_name <- paste0(output_path,"/", out.fname)

print(ref.prefix)
print(loc.file)
print(info.file)
print(sample.overlap.file)
print(phenos)
print(locus.number)
print(target)
print(out.fname)
print(output_path)
print(output_file_name)

### Load package

# if (!require(LAVA, character.only = TRUE)) {
#   install.packages("LAVA")
# }

library(LAVA)




# if (!dir.exists(output_path)) {
#   # If the folder doesn't exist, create it
#   dir.create(output_path, recursive = TRUE)
#   cat("Folder created successfully.\n")
# }


### Read in data
loci = read.loci(loc.file); n.loc = nrow(loci)
input = process.input(info.file, sample.overlap.file, ref.prefix, phenos)

### Set univariate pvalue threshold
univ.p.thresh = 0.05/nrow(loci)

### Analyse
print(paste("Starting LAVA analysis for",locus.number,"loci"))
progress = ceiling(quantile(1:locus.number, seq(.05,1,.05)))   # (if you want to print the progress)

u=b=list()
for (i in locus.number) {
  tryCatch({
  if (i %in% progress) print(paste("..",names(progress[which(progress==i)])))     # (printing progress)
  locus = process.locus(loci[i,], input)                                          # process locus

  # It is possible that the locus cannot be defined for various reasons (e.g. too few SNPs), so the !is.null(locus) check is necessary before calling the analysis functions.
  if (!is.null(locus)) {
    # extract some general locus info for the output
    loc.info = data.frame(locus = locus$id,
                          chr = locus$chr,
                          start = locus$start,
                          stop = locus$stop,
                          n.snps = locus$n.snps,
                          n.pcs = locus$K)

    # run the univariate and bivariate tests
    loc.out = run.univ.bivar(locus, univ.thresh = univ.p.thresh, target = target)
    u[[i]] = cbind(loc.info, loc.out$univ)
    if(!is.null(loc.out$bivar)) b[[i]] = cbind(loc.info, loc.out$bivar)
  }
  }, error=function(e){cat("ERROR :",conditionMessage(e), "\n")})
}

# save the output
write.table(do.call(rbind,u), paste0(output_file_name, "_", i, ".univ.lava"), row.names=F,quote=F,col.names=T)
write.table(do.call(rbind,b), paste0(output_file_name, "_", i, ".bivar.lava"), row.names=F,quote=F,col.names=T)

print(paste0("Done! Analysis output written to ",out.fname, "_", i, ".*.lava"))
