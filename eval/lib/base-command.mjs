import { Command, Option } from "clipanion";
import path from "path";

function resolvePath(unresolvedPath) {
  if (!path.isAbsolute(unresolvedPath)) {
    return path.resolve(process.cwd(), unresolvedPath);
  }
  return unresolvedPath;
}

export default class BaseCommand extends Command {
  evalDataDir = Option.String("--eval-data-dir", { required: true });

  dbPath() {
    return path.join(resolvePath(this.evalDataDir), "commits.db");
  }

  amendmentsPath() {
    return path.join(resolvePath(this.evalDataDir), "amendments.json");
  }
}
