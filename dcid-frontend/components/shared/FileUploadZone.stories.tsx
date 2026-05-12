import { FileUploadZone } from "./FileUploadZone";

export default {
  title: "Shared/FileUploadZone",
};

export const Default = () => (
  <div className="max-w-xl">
    <FileUploadZone onFilesSelected={() => undefined} />
  </div>
);
