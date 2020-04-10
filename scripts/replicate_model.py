import xml.etree.ElementTree as ET
import sys
import argparse
import tempfile
import shutil
import os
import math
from zipfile import ZipFile

DEBUG_LOGGING = False
LOCAL_TEMP_DIR = False
PRESERVE_TEMP_DIR = False

def log(string=None):
    if (string != None):
        print("replicate_model: " + string)
    else:
        print("replicate_model:")

def log_debug(string=None):
    if (DEBUG_LOGGING):
        log(string)
        
def extract_namespace(element):
    tag = element.tag
    if tag[0] == '{':
        ns = tag[0:].split("}")[0] + '}'
    return ns

def measure_model(model_root):
    vertices = model_root.find(resources_tag+'/'+object_tag+'/'+mesh_tag+'/'+vertices_tag)
    
    max_x = -(sys.maxsize-1)
    min_x = sys.maxsize
    max_y = -(sys.maxsize-1)
    min_y = sys.maxsize
    
    for vertex in list(vertices):
        x = float(vertex.get('x'))
        y = float(vertex.get('y'))
        
        if (x < min_x): min_x = x
        if (x > max_x): max_x = x
        if (y < min_y): min_y = y
        if (y > max_y): max_y = y

    log_debug("min_x: " + str(min_x))
    log_debug("max_x: " + str(max_x))
    log_debug("min_y: " + str(min_y))
    log_debug("max_y: " + str(max_y))
    log_debug()

    return max_x-min_x, max_y-min_y

arg_parser = argparse.ArgumentParser()

required_options = arg_parser.add_argument_group('required options')
required_options.add_argument("-m", "--model", help="Baseline .3mf model file with one instance of the model to be duplicated", required=True)
required_options.add_argument("-o", "--output", help="Output .3mf model file with one instance of the model to be duplicated")
arg_parser.add_argument("-w", "--bed_width", help="Width of the print bed in mm (default: 250)", type=int, default=250)
arg_parser.add_argument("-d", "--bed_depth", help="Depth of the print bed in mm (default: 210)", type=int, default=210)
arg_parser.add_argument("-x", "--x_spacing", help="X-axis spacing in mm from the start of one instance of the model to the next", default=0, type=float)
arg_parser.add_argument("-X", "--x_gap", help="X-axis gap from the edge of one model to the next", default=5, type=float)
arg_parser.add_argument("-y", "--y_spacing", help="Y-axis spacing in mm from the start of one instance of the model to the next", default=0, type=float)
arg_parser.add_argument("-Y", "--y_gap", help="Y-axis gap from the edge of one model to the next", default=5, type=float)
arg_parser.add_argument("--x_offset", help="X-axis offset from both edges of the bed", default=0, type=float)
arg_parser.add_argument("--y_offset", help="Y-axis offset from both edges of the bed", default=0, type=float)
arg_parser.add_argument("--left_offset", help="Offset from the left side of the bed (x-axis, left side only)", default=0, type=float)
arg_parser.add_argument("--right_offset", help="Offset from the right side of the bed (x-axis, right side only)", default=0, type=float)
arg_parser.add_argument("--front_offset", help="Offset from the front of the bed (y-axis, front only)", default=0, type=float)
arg_parser.add_argument("--rear_offset", help="Offset from the back of bed (y-axis, back only)", default=0, type=float)

args = arg_parser.parse_args()

log_debug("args: " + str(args))
log_debug()

# Get temp dir to extract .3mf into
if (LOCAL_TEMP_DIR):
    temp_project_dir = 'replicate_model.tmp'
    try:
        shutil.rmtree(temp_project_dir)
    except:
        pass
    os.mkdir(temp_project_dir)
else:
    temp_project_dir = tempfile.mkdtemp(prefix="multiply_model")
    # Don't preserve the temp dir if we are using a system provided dir
    PRESERVE_TEMP_DIR = False
    log_debug("temp dir: " + temp_project_dir)

# Extract .3mf project into temp dir
with ZipFile(args.model, 'r') as zipObj:
    zipObj.extractall(temp_project_dir)

model_file = os.path.join(temp_project_dir, '3D', '3dmodel.model')
slicer_model_config_file = os.path.join(temp_project_dir, 'Metadata', 'Slic3r_PE_model.config')

model_tree = ET.parse(model_file)
model_root = model_tree.getroot()

ns = extract_namespace(model_root)

resources_tag = 'resources'
object_tag = 'object'
mesh_tag = 'mesh'
vertices_tag = 'vertices'
vertex_tag = 'vertex'
build_tag = 'build'
item_tag = 'item'
components_tag = 'components'
component_tag = 'component'

if (ns != None):
    ET.register_namespace('', ns[1:-1])
    resources_tag = ns + resources_tag
    object_tag = ns + object_tag
    mesh_tag = ns + mesh_tag
    vertices_tag = ns + vertices_tag
    vertex_tag = ns + vertex_tag
    build_tag = ns + build_tag
    item_tag = ns + item_tag
    components_tag = ns + components_tag
    component_tag = ns + component_tag

# Calculate X / Y dimensions of model

log("Bed dimensions: [" + str(args.bed_width) + " x " + str(args.bed_depth) + "]")
log("Bed keep-out:")
log("                Rear: " + str(args.y_offset + args.rear_offset))
log("          -----------------------")
log("          |                     |")
log("Left: " + str(args.x_offset + args.left_offset) + " |                     | Right: " + str(args.x_offset + args.right_offset))
log("          |                     |")
log("          -----------------------")
log("                Front: " + str(args.y_offset + args.front_offset))
log()
log("Processing project file (.3mf): " + args.model)

x_dim, y_dim = measure_model(model_root)
log("Model dimensions: [" + str(x_dim) + " x " + str(y_dim) + "]")

x_print_avail = args.bed_width - (2 * args.x_offset) - args.left_offset - args.right_offset
y_print_avail = args.bed_depth - (2 * args.y_offset) - args.front_offset - args.rear_offset

log_debug("Available print area = [" + str(x_print_avail) + " x " + str(y_print_avail) + "]")

if (args.x_spacing != 0):
    num_cols = ((x_print_avail - x_dim) // args.x_spacing) + 1
    print_width = ((num_cols-1) * args.x_spacing) + x_dim
else:
    num_cols = x_print_avail // x_dim
    if (((num_cols * x_dim) + ((num_cols - 1) * args.x_gap)) > x_print_avail):
        num_cols -= 1
    print_width = (num_cols * x_dim) + ((num_cols - 1) * args.x_gap)

if (args.y_spacing != 0):
    num_rows = ((y_print_avail - y_dim) // args.y_spacing) + 1
    print_depth = ((num_rows-1) * args.y_spacing) + y_dim
else:
    num_rows = y_print_avail // y_dim
    if (((num_rows * y_dim) + ((num_rows - 1) * args.y_gap)) > y_print_avail):
        num_rows -= 1
    print_depth = (num_rows * y_dim) + ((num_rows - 1) * args.y_gap)

num_rows = int(num_rows)
num_cols = int(num_cols)

log("Printing " + str(num_rows*num_cols) + " objects [" + str(num_cols) + " x " + str(num_rows) + "]")

# Assume the bottom, left corner of the bed is the origin and lay it out from there
x_offset = (x_dim / 2) + ((x_print_avail - print_width) / 2) + args.x_offset + args.left_offset
y_offset = (y_dim / 2) + ((y_print_avail - print_depth) / 2) + args.y_offset + args.front_offset

log_debug("Actual print area: [" + str(print_width) + " x " + str(print_depth) + "]")
log_debug("Print starts at: [" + str(x_offset - (x_dim / 2)) + ", " + str(y_offset - (y_dim / 2)) + "]")

model_origin = []
for col in range(num_cols):
    if (args.x_spacing != 0):
        x = x_offset + (col * args.x_spacing)
    else:
        x = x_offset + (col * (x_dim + args.x_gap))
        
    for row in range(num_rows):
        if (args.y_spacing != 0):
            y = y_offset + (row * args.y_spacing)
        else:
            y = y_offset + (row * (y_dim + args.y_gap))
        
        model_origin.append([x,y])
        
#print("Model: " + str(model_origin))

# Each entry in build represents a single instance an object on the build plate
# It includes a transform with the X and Y coordinates of the object's origin (center)
# We need to update the entries that are there and add new ones for those we don't have

base_object_id = 0;
build_plate_z = 0;
index = 0;
next_object_id = 0;

build_entries = model_root.find(build_tag)

for build in list(build_entries):
    build_object_id = int(build.get('objectid'))
    log_debug("Object to replecate: objectid = " + str(build_object_id))
        
    if (next_object_id == 0):
        base_object_id = build_object_id
    else:
        if (build_object_id != base_object_id):
            log("WARNING - found extra object in model: objectid = %d", build_object_id)
            log("IGNORING...")
            next_object_id = build_object_id + 1   # Skip
            continue
    transform = build.get('transform')
    transform_elements = transform.split()
    
    if (next_object_id == 0):
        build_plate_z = transform_elements[11]
        next_object_id = base_object_id

    transform_elements[9] = str(model_origin[index][0])
    transform_elements[10] = str(model_origin[index][1])
    build.set('transform', ' '.join(transform_elements))
    build.tail = os.linesep + '  '
    index += 1
    next_object_id += 1;
    
first_new_object_id = next_object_id

resources = model_root.find(resources_tag)

for i in range(index, (num_rows*num_cols)):
    transform = '1 0 0 0 1 0 0 0 1 ' + str(round(model_origin[i][0], 2)) + ' ' + str(round(model_origin[i][1], 2)) + ' ' + build_plate_z
    
    new_element = ET.SubElement(build, item_tag, attrib={'id' : str(next_object_id), 'transform' : transform, 'printable' : '1'})
    new_element.tail = os.linesep + '  '
    
    new_object = ET.SubElement(resources, object_tag, attrib={'objectid' : str(next_object_id)})
    components = ET.SubElement(new_object, components_tag)
    component = ET.SubElement(components, component_tag, attrib={'objectid' : str(base_object_id), 'type' : 'model'})
    new_object.tail = os.linesep + '  '
    components.tail = os.linesep + '   '
    component.tail = os.linesep + '    '

    next_object_id += 1;
    
model_tree.write(model_file, xml_declaration=True)

slicer_config_tree = ET.parse(slicer_model_config_file)
slicer_config_root = slicer_config_tree.getroot()

object = slicer_config_root.find('object')
object.set('instances_count', str(next_object_id-1))

slicer_config_tree.write(slicer_model_config_file, xml_declaration=True)

log("Output project file (.3mf): " + args.output)
with ZipFile(args.output, 'w') as zipObj:
    prefix = os.path.join(temp_project_dir, '')
    for folderName, subfolders, filenames in os.walk(temp_project_dir):
        for fn in filenames:
            filePath = os.path.join(folderName, fn)
            zipObj.write(filePath, arcname=filePath[filePath.startswith(prefix) and len(prefix):])

# All done - delete temp dir
if (not PRESERVE_TEMP_DIR):
    shutil.rmtree(temp_project_dir)

log("Complete.")
