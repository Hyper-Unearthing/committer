import { Command, Option, runExit } from "clipanion";
import DumpCommitsCommand from "./eval/dump-commits-command.mjs";
import ProcessCommitsCommand from "./eval/process-commits-for-eval-command.mjs";
import RunEvaluationCommand from "./eval/run-evaluation.mjs";
runExit([DumpCommitsCommand, ProcessCommitsCommand, RunEvaluationCommand]);
