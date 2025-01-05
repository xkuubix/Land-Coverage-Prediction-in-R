library("randomForest")
library("ggplot2")
library("caret")
library("scales")
library("reshape2")

set.seed(42)

labels <- read.csv("labels.csv")
sat <- read.csv("satellite_image.csv")

train_index <- caret::createDataPartition(labels$label, p = 0.8, list = FALSE)
train_data <- labels[train_index, ]
val_data <- labels[-train_index, ]

rf_model <- randomForest(
  as.factor(label) ~ .,
  data = train_data[, c(-2, -3)],
  ntree = 100, importance = TRUE
)

val_preds <- predict(rf_model, newdata = val_data)
conf_matrix <- table(val_data$label, val_preds)
print(conf_matrix)
accuracy <- sum(diag(conf_matrix)) / sum(conf_matrix)
cat("Validation Accuracy: ", accuracy, "\n")

sat$pred_label <- predict(rf_model, newdata = sat)

p1 <- ggplot(sat, aes(x = x, y = y)) +
  geom_raster(aes(fill = rgb(band4, band3, band2))) +
  scale_fill_identity() +
  geom_point(data = labels, aes(x = x, y = y,
                                color = as.factor(label)),
             size = 2) +
  scale_color_viridis_d(name = "Label") +
  theme_minimal() +
  theme(
    axis.text = element_blank(),
    axis.ticks = element_blank(),
    axis.title = element_blank(),
    panel.grid = element_blank(),
    legend.position = "right",
    legend.box.margin = margin(t = 0, r = 0, b = 0, l = 0)
  ) +
  coord_fixed() + # Fix aspect ratio
  labs(title = "True Color Raster with Labels")

print(true_color_plot)

p2 <- ggplot(sat, aes(x = x, y = y)) +
  geom_raster(aes(fill = as.factor(pred_label))) +
  scale_fill_viridis_d(name = "Predicted Label") +
  theme_minimal() +
  theme(
    axis.text = element_blank(),
    axis.ticks = element_blank(),
    axis.title = element_blank(),
    panel.grid = element_blank(),
    legend.position = "right",
    legend.box.margin = margin(t = 0, r = 0, b = 0, l = 0)
  ) +
  coord_fixed() +
  labs(title = "Predicted Land Cover Map")

print(pred_map)
conf_mat <- table(val_data$label, val_preds)

conf_matrix_df <- as.data.frame(as.table(conf_mat))
colnames(conf_matrix_df) <- c("True_Label", "Predicted_Label", "Frequency")

p3 <- ggplot(conf_matrix_df, aes(x = Predicted_Label, y = True_Label, fill = Frequency)) +
  geom_tile(color = "white") +
  scale_fill_gradient(low = "white", high = "blue", name = "Frequency") +
  geom_text(aes(label = Frequency), color = "black", size = 4) +
  theme_minimal() +
  labs(title = "Confusion Matrix",
       x = "Predicted Label",
       y = "True Label") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

ggsave("p1.jpeg", plot = p1, width = 10, height = 8)
ggsave("p2.jpeg", plot = p2, width = 10, height = 8)
ggsave("p3.jpeg", plot = p3, width = 10, height = 8)

val_data$label <- as.factor(val_data$label)
val_preds <- as.factor(val_preds)
common_levels <- union(levels(val_data$label), levels(val_preds))
val_data$label <- factor(val_data$label, levels = common_levels)
val_preds <- factor(val_preds, levels = common_levels)
conf_mat <- confusionMatrix(val_preds, val_data$label)

print(conf_mat)

train_class_counts <- table(train_data$label)
print("Training data class counts:")
print(train_class_counts)

val_class_counts <- table(val_data$label)
print("Validation data class counts:")
print(val_class_counts)
