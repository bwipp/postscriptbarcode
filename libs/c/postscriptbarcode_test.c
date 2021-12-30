#include "postscriptbarcode.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main() {

  char *name = "databaromni";
  char *data = "THIS IS CODE 39";
  char *options = "includetext";
  char *tmp, *ps, *abc;
  char **families;
  unsigned short num_families, i;

  BWIPP *ctx = bwipp_load_from_file("../../build/monolithic/barcode.ps");
  BWIPP *ctx2 =
      bwipp_load_from_file("../../build/monolithic_package/barcode.ps");

  printf("Version: %s\n", bwipp_get_version(ctx));
  printf("Version: %s\n", bwipp_get_version(ctx2));

  tmp = bwipp_emit_required_resources(ctx, name);
  ps = malloc(strlen(tmp) + 1000 * sizeof(char));
  ps[0] = '\0';
  strcat(ps, "%!PS\n");
  strcat(ps, tmp);
  bwipp_free(tmp);
  strcat(ps, "gsave\n");
  strcat(ps, "50 150 translate\n");
  tmp = bwipp_emit_exec(ctx, name, data, options);
  strcat(ps, tmp);
  bwipp_free(tmp);
  strcat(ps, "grestore\n");
  /*	printf("%s\n",ps); */
  bwipp_free(ps);

  abc = bwipp_emit_all_resources(ctx);
  /*	printf("%s",abc);
   */
  bwipp_free(abc);

  char *families_str = bwipp_list_families_as_string(ctx);
  //	printf("%s\n",families_str);
  bwipp_free(families_str);

  char *members_str =
      bwipp_list_family_members_as_string(ctx, "Two-dimensional");
  //	printf("%s\n",members_str);
  bwipp_free(members_str);

  char *properties_str = bwipp_list_properties_as_string(ctx, "qrcode");
  //	printf("%s\n",properties_str);
  bwipp_free(properties_str);

  num_families = bwipp_list_families(ctx, &families);
  for (i = 0; i < num_families; i++) {
    char **members;
    unsigned short num_members, j;
    char *family = families[i];
    //		printf("***%s***\n",family);
    num_members = bwipp_list_family_members(ctx, &members, family);
    for (j = 0; j < num_members; j++) {
      char **properties;
      unsigned short num_properties, k;
      char *bcname = members[j];
      //			printf("--%s--\n",bcname);
      num_properties = bwipp_list_properties(ctx, &properties, bcname);
      for (k = 0; k < num_properties; k++) {
        const char *val = bwipp_get_property(ctx, bcname, properties[k]);
        //				printf("%s: %s\n",properties[k],val);
      }
      bwipp_free(properties);
    }
    bwipp_free(members);
  }
  bwipp_free(families);

  bwipp_unload(ctx);
  bwipp_unload(ctx2);

  return 0;
}
