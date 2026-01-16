export default {
  "*.sh": ["shellcheck -x -e SC1091"],
  "*.md": ["markdownlint --fix"],
};
