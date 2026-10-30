# Documentation graphic only; does not fit or evaluate a model.
# Source: Cluster Commanders' 2025 Sandia Data Challenge presentation, slide 13.
# Values are the printed, rounded, historical IN-SAMPLE deviance explained.

values <- c(1.2, 8.7, 12.5)
labels <- c("Build settings", "+ Plate effects", "+ Spatial smooth")

# Use R's configured PNG device (Quartz on macOS, typically Cairo on Linux).
png("model-fit.png", width = 1500, height = 760, res = 160)
par(mar = c(5, 5, 4.5, 2), bg = "white", family = "sans", las = 1)
centers <- barplot(values, names.arg = labels, ylim = c(0, 15),
                  col = c("#B7C9DC", "#6187AC", "#164B76"), border = NA,
                  axes = FALSE, cex.names = 1.05, space = 0.65)
axis(2, at = seq(0, 15, 5), labels = paste0(seq(0, 15, 5), "%"),
     col = NA, col.ticks = NA, col.axis = "#506176")
text(centers, values + 0.65, labels = paste0(values, "%"),
     font = 2, cex = 1.35, col = "#16324F")
mtext("Deviance explained", side = 2, line = 3.5, las = 0, cex = 1.0)
title(main = "Accounting for plate and spatial variation", adj = 0,
      col.main = "#16324F", cex.main = 1.35)
mtext("Historical in-sample fit | Original presentation, slide 13 | Not held-out performance",
      side = 1, line = 3.4, cex = 0.78, col = "#506176")
invisible(dev.off())
